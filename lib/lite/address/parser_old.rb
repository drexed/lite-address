# frozen_string_literal: true

require 'countries' unless defined?(ISO3166::Country)
require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class Parser

      attr_reader :address, :country_code

      def initialize(address, country_code: 'US')
        @address = address
        @country_code = country_code
      end

      class << self

        def call(address, options = {})
          instance = new(address, country_code: options.delete(:country_code) || 'US')
          instance.call(options)
        end

      end

      def call(options = {})
        return parse_intersectional_address(options) if regexp_corner.match(address)

        parse_formal_address(options) || parse_informal_address(options)
      end

      def parse_formal_address(options = {})
        return unless match = regexp_address.match(preclean_address(address))

        to_address(match_to_hash(match), options)
      end

      def parse_informal_address(options = {})
        return unless match = regexp_informal_address.match(preclean_address(address))

        to_address(match_to_hash(match), options)
      end

      def parse_intersectional_address(options = {})
        return unless match = regexp_intersection.match(preclean_address(address))

        hash = match_to_hash(match)
        intersection_parts(match, hash, 'street')
        intersection_parts(match, hash, 'street_type')

        if hash['street_type'] && (!hash['street_type2'] || (hash['street_type'] == hash['street_type2']))
          type = hash['street_type'].dup

          if type.gsub!(/s\W*$/i, '') && (/\A#{regexp_street_type}\z/io =~ type)
            hash['street_type'] = hash['street_type2'] = type
          end
        end

        to_address(hash, options)
      end

      protected

      def cardinal_codes
        @cardinal_codes ||= cardinal_types.invert
      end

      def cardinal_types
        @cardinal_types ||= begin
          file_path = File.expand_path('types/cardinal.yml', File.dirname(__FILE__))
          YAML.load_file(file_path)
        end
      end

      def country_class
        @country_class ||= ISO3166::Country.new(country_code)
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
          'state' => subdivision_codes
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
          hash[abbr] = /\b (?: #{abbr}|#{Regexp.quote(type)} ) \b/ix
        end
      end

      def subdivision_codes
        @subdivision_codes ||= subdivision_names.invert
      end

      def subdivision_names
        @subdivision_names ||= country_class.subdivisions.each_with_object({}) do |(code, subdivision), hash|
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

      private

      def preclean_address(address)
        address.delete_prefix('(').delete_suffix(')')
      end

      def match_to_hash(match)
        match.names.each_with_object({}) do |name, hash|
          value = match[name]
          next unless value

          hash[name] = value
        end
      end

      def intersection_parts(match, hash, part)
        parts = regexp_intersection.named_captures[part].map { |i| match[i.to_i] }.compact
        hash[part] = parts[0] if parts[0]
        hash["#{part}2"] = parts[1] if parts[1]
      end

      def to_address(input, args)
        # strip off some punctuation and whitespace
        input.each do |key, string|
          string.strip!

          case key
          when 'number' then string.gsub!(%r{[^\w\s\-\#&/.]}, '')
          else string.gsub!(%r{[^\w\s\-\#&/]}, '')
          end
        end

        input['redundant_street_type'] = false
        if input['street'] && !input['street_type']
          match = regexp_street.match(input['street'])
          input['street_type'] = match['street_type'] if match
          input['redundant_street_type'] = true
        end

        ## abbreviate unit prefixes
        unit_abbreviations.each_pair do |regex, abbr|
          regex.match(input['unit_prefix']) { |_m| input['unit_prefix'] = abbr }
        end

        normalization_map.each_pair do |key, map|
          next unless input[key]

          mapping = map[input[key].downcase]
          input[key] = mapping if mapping
        end

        if args[:avoid_redundant_street_type]
          ['', '1', '2'].each do |suffix|
            street = input["street#{suffix}"]
            street_type = input["street_type#{suffix}"]
            next if !street || !street_type

            type_regexp = street_type_matchers[street_type.downcase]
            input.delete("street_type#{suffix}") if type_regexp.match(street)
          end
        end

        # attempt to expand CARDINAL_TYPES prefixes on place names
        input['city']&.gsub!(/^(#{regexp_cardinal_code})\s+(?=\S)/o) do |match|
          "#{cardinal_codes[match[0].upcase]} "
        end

        # Fix cases with a dirty ordinal indicator:
        # Sometimes parcel data will have addresses like
        # "1 1ST ST" as "1 1 ST ST"
        input['street']&.gsub!(/\A(\d+\s+st|\d+\s+nd|\d+\s+rd|\d+\s+th)\z/i) do |_match|
          input['street'].gsub(/\s+/, '')
        end

        %w[street street_type street2 street_type2 city unit_prefix].each do |k|
          input[k] = input[k].split.map(&:capitalize).join(' ') if input[k]
        end

        Lite::Address::Details.new(input)
      end











      def regexp_address
        /
          \A
          [^\w\x23]* # skip non-word chars except # (eg unit)
          #{regexp_number} \W*
          #{regexp_street}\W+
          (?:#{regexp_unit}\W+)?
          #{regexp_place}
          \W* # require on non-word chars at end
          \z  # right up to end of string
        /ix
      end

      def regexp_avoid_unit
        /(?:[^\#\w]+|\Z)/
      end

      def regexp_cardinal_code
        values = cardinal_codes.keys
        Regexp.new(values.join('|'), Regexp::IGNORECASE)
      end

      def regexp_cardinal_type
        values = cardinal_types.keys
        cardinal_types.values.sort { |a, b| b.size <=> a.size }.map do |c|
          values << [Regexp.quote(c.gsub(/(\w)/, '\1.')), Regexp.quote(c)]
        end
        Regexp.new(values.join('|'), Regexp::IGNORECASE)
      end

      def regexp_city_state
        /(?:(?<city> [^\d,]+?)\W+(?<state> #{regexp_subdivision}))/ix
      end

      def regexp_corner
        /(?:\band\b|\bat\b|&|@)/i
      end

      def regexp_informal_address
        /
          \A
          \s*
          (?:#{regexp_unit} #{regexp_separator} #{regexp_place})?
          (?:#{regexp_number})? \W*
          #{regexp_street} #{regexp_avoid_unit}
          (?:#{regexp_unit} #{regexp_separator})?
          (?:#{regexp_place})?
        /ix
      end

      def regexp_intersection
        /\A\W*
          #{regexp_street}\W*?
          \s+#{regexp_corner}\s+
          # (?{ exists $_{$_} and $_{$_.1} = delete $_{$_} for (qw{prefix street type suffix})})
          #{regexp_street}\W+
          # (?{ exists $_{$_} and $_{$_.2} = delete $_{$_} for (qw{prefix street type suffix})})
          #{regexp_place}
          \W*\z
        /ix
      end

      def regexp_number
        # Utah and Wisconsin have a more elaborate system of block numbering
        # http://en.wikipedia.org/wiki/House_number#Block_numbers
        /(?<number>(n|s|e|w)?\d+[.-]?\d*)(?=\D)/ix
      end

      def regexp_place
        /(?:#{regexp_city_state}\W*)? (?:#{regexp_postal_code})?/ix
      end

      def regexp_postal_code
        /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/
      end

      def regexp_separator
        /(?:\W+|\Z)/
      end

      def regexp_street
        /
          (?:
            # NOTE: that expressions like [^,]+ may scan more than you expect
            # special case for addresses like 100 South Street
            (?:
              (?<street> #{regexp_cardinal_type})\W+
              (?<street_type> #{regexp_street_type})\b
            )
            | (?:(?<prefix> #{regexp_cardinal_type})\W+)?
            (?:
              (?<street> [^,]*\d)
              (?:[^\w,]* (?<suffix> #{regexp_cardinal_type})\b)
              |
              (?<street> [^,]+)
              (?:[^\w,]+(?<street_type> #{regexp_street_type})\b)
              (?:[^\w,]+(?<suffix> #{regexp_cardinal_type})\b)?
              |
              (?<street> [^,]+?)
              (?:[^\w,]+(?<street_type> #{regexp_street_type})\b)?
              (?:[^\w,]+(?<suffix> #{regexp_cardinal_type})\b)?
            )
          )
        /ix
      end

      def test_matchers
        street_types.each_with_object({}) do |(key, val), hash|
          hash[key] = true
          hash[val] = true
        end
      end

      def regexp_street_type
        values = (street_types.keys + street_types.values).uniq
        Regexp.new(values.join('|'), Regexp::IGNORECASE)
      end

      def regexp_subdivision
        values = subdivision_codes.flatten.map { |code| Regexp.quote(code) }
        Regexp.new("\b#{values.join('|')}\b", Regexp::IGNORECASE)
      end

      def regexp_unit
        %r{
          (?:
            (?:
              (?:#{regexp_unit_prefixed_numbered} \W*)
              | (?<unit_prefix> \#)\W*
            )
            (?<unit> [\w/-]+)
          ) | #{regexp_unit_prefixed_unnumbered}
        }ix
      end

      def regexp_unit_prefixed_numbered
        /(?<unit_prefix>#{unit_abbreviations_numbered.keys.join('|')})(?![a-z])/ix
      end

      def regexp_unit_prefixed_unnumbered
        /(?<unit_prefix>#{unit_abbreviations_unnumbered.keys.join('|')})\b/ix
      end

    end
  end
end
