# frozen_string_literal: true

require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class Regexp

      attr_reader :country

      def initialize(country)
        @country = country
      end

      ###########################################
      # Maps
      ###########################################

      def cardinal_codes
        @cardinal_codes ||= cardinal_types.invert
      end

      def cardinal_types
        @cardinal_types ||= begin
          file_path = File.expand_path('types/cardinal.yml', File.dirname(__FILE__))
          YAML.load_file(file_path)
        end
      end

      def normalization_map
        @normalization_map ||= {
          'prefix' => cardinal_types,
          'prefix1' => cardinal_types,
          'prefix2' => cardinal_types,
          'suffix' => cardinal_types,
          'suffix1' => cardinal_types,
          'suffix2' => cardinal_types,
          'street_type' => street_types,
          'street_type1' => street_types,
          'street_type2' => street_types,
          'state' => subdivision_names
        }
      end

      def street_types
        @street_types ||= begin
          file_path = File.expand_path('types/street.yml', File.dirname(__FILE__))
          YAML.load_file(file_path)
        end
      end

      def street_type_matchers
        @street_type_matchers ||= street_types.each_with_object({}) do |(type, abbr), hash|
          hash[abbr] = /\b (?: #{abbr}|#{::Regexp.quote(type)} ) \b/ix
        end
      end

      def subdivision_codes
        @subdivision_codes ||= subdivision_names.invert
      end

      def subdivision_names
        @subdivision_names ||= country.subdivisions.each_with_object({}) do |(code, subdivision), hash|
          hash[subdivision.name.downcase] = code
        end
      end

      def unit_abbreviations
        # http://pe.usps.com/text/pub28/pub28c2_003
        @unit_abbreviations ||= unit_abbreviations_numbered.merge(unit_abbreviations_unnumbered)
      end

      def unit_abbreviations_numbered
        @unit_abbreviations_numbered ||= {
          /(?:ap|dep)(?:ar)?t(?:me?nt)?/i => 'Apt',
          /p\W*[om]\W*b(?:ox)?/i => 'PO Box',
          /bu?i?ldi?n?g/i => 'Bldg',
          /dep(artmen)?t/i => 'Dept',
          /flo*r?/i => 'Floor',
          /ha?nga?r/i => 'Hanger',
          /lo?t/i => 'Lot',
          /ro*m/i => 'Room',
          /pier/i => 'Pier',
          /slip/i => 'Slip',
          /spa?ce?/i => 'Space',
          /stop/i => 'Stop',
          /drawer/i => 'Drawer',
          /su?i?te/i => 'Suite',
          /tra?i?le?r/i => 'Trailer',
          /\w*(?<!po\W)box/i => 'Box',
          /uni?t/i => 'Unit'
        }
      end

      def unit_abbreviations_unnumbered
        @unit_abbreviations_unnumbered ||= {
          /ba?se?me?n?t/i => 'Basement',
          /fro?nt/i => 'Front',
          /lo?bby/i => 'Lobby',
          /lowe?r/i => 'Lower',
          /off?i?ce?/i => 'Office',
          /pe?n?t?ho?u?s?e?/i => 'PH',
          /rear/i => 'Rear',
          /side/i => 'Side',
          /uppe?r/i => 'Upper'
        }
      end

      ###########################################
      # Regexps
      ###########################################

      def avoid_unit
        @avoid_unit ||= /(?:[^\#\w]+|\Z)/ix
      end

      def cardinal_code
        @cardinal_code ||= begin
          values = cardinal_codes.keys
          ::Regexp.new(values.join('|'), ::Regexp::IGNORECASE)
        end
      end

      def cardinal_type
        @cardinal_type ||= begin
          values = cardinal_types.keys
          cardinal_types.values.sort { |a, b| b.size <=> a.size }.map do |c|
            values << [::Regexp.quote(c.gsub(/(\w)/, '\1.')), ::Regexp.quote(c)]
          end
          ::Regexp.new(values.join('|'), ::Regexp::IGNORECASE)
        end
      end

      def city_state
        @city_state ||= /(?:(?<city> [^\d,]+?)\W+(?<state> #{subdivision}))/ix
      end

      def corner
        @corner ||= /(?:\band\b|\bat\b|&|@)/ix
      end

      def formal_address
        @formal_address ||= begin
          /\A[^\w\x23]*
            #{number} \W*
            #{street}\W+
            (?:#{unit}\W+)?
            #{place}\W*\z
          /ix
        end
      end

      def informal_address
        @informal_address ||= begin
          /\A\s*
            (?:#{unit} #{separator} #{place})?
            (?:#{number})? \W*
            #{street} #{avoid_unit}
            (?:#{unit} #{separator})?
            (?:#{place})?
          /ix
        end
      end

      def intersectional_address
        @intersectional_address ||= begin
          /\A\W*
            #{street}\W*?
            \s+#{corner}\s+
            #{street}\W+
            #{place}\W*\z
          /ix
        end
      end

      def number
        # Utah and Wisconsin have a more elaborate system of block numbering
        # http://en.wikipedia.org/wiki/House_number#Block_numbers
        @number ||= /(?<number>(n|s|e|w)?\d+[.-]?\d*)(?=\D)/ix
      end

      def place
        @place ||= /(?:#{city_state}\W*)? (?:#{postal_code})?/ix
      end

      def postal_code
        @postal_code ||= /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/ix
      end

      def separator
        @separator ||= /(?:\W+|\Z)/ix
      end

      def street
        @street ||= begin
          /(?:
            (?:
              (?<street> #{cardinal_type})\W+
              (?<street_type> #{street_type})\b
            )
            | (?:(?<prefix> #{cardinal_type})\W+)?
            (?:
              (?<street> [^,]*\d)
              (?:[^\w,]* (?<suffix> #{cardinal_type})\b)
              |
              (?<street> [^,]+)
              (?:[^\w,]+(?<street_type> #{street_type})\b)
              (?:[^\w,]+(?<suffix> #{cardinal_type})\b)?
              |
              (?<street> [^,]+?)
              (?:[^\w,]+(?<street_type> #{street_type})\b)?
              (?:[^\w,]+(?<suffix> #{cardinal_type})\b)?
            )
          )/ix
        end
      end

      def street_type
        @street_type ||= begin
          values = (street_types.keys + street_types.values).uniq
          ::Regexp.new(values.join('|'), ::Regexp::IGNORECASE)
        end
      end

      def subdivision
        @subdivision ||= begin
          values = subdivision_codes.flatten.map { |code| ::Regexp.quote(code) }
          ::Regexp.new("\b#{values.join('|')}\b", ::Regexp::IGNORECASE)
        end
      end

      def unit # TODO find better version
        @unit ||= %r{
          (?:
            (?:
              (?:#{unit_numbered} \W*)
              | (?<unit_prefix> \#)\W*
            )
            (?<unit> [\w/-]+)
          ) | #{unit_unnumbered}
        }ix
      end

      def unit_numbered
        @unit_numbered ||= /(?<unit_prefix>#{unit_abbreviations_numbered.keys.join('|')})(?![a-z])/ix
      end

      def unit_unnumbered
        @unit_unnumbered ||= /(?<unit_prefix>#{unit_abbreviations_unnumbered.keys.join('|')})\b/ix
      end

    end
  end
end
