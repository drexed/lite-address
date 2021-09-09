# frozen_string_literal: true

module Lite
  module Address
    class Regexp

      attr_reader :list

      def initialize(list)
        @list = list
      end

      def avoid_unit
        @avoid_unit ||= /(?:[^\#\w]+|\Z)/ix
      end

      def cardinal_code
        @cardinal_code ||= begin
          values = list.cardinal_codes.keys
          ::Regexp.new(values.join('|'), ::Regexp::IGNORECASE)
        end
      end

      def cardinal_type
        @cardinal_type ||= begin
          values = list.cardinal_types.each_with_object([]) do |(key, val), array|
            array << key
            array << [::Regexp.quote(val.gsub(/(\w)/, '\1.')), ::Regexp.quote(val)]
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
        @formal_address ||= /\A[^\w\x23]*
          #{number} \W*
          #{street}\W+
          (?:#{unit}\W+)?
          #{place}\W*\z
        /ix
      end

      def informal_address
        @informal_address ||= /\A\s*
          (?:#{unit} #{separator} #{place})?
          (?:#{number})? \W*
          #{street} #{avoid_unit}
          (?:#{unit} #{separator})?
          (?:#{place})?
        /ix
      end

      def intersectional_address
        @intersectional_address ||= /\A\W*
          #{street}\W*?
          \s+#{corner}\s+
          #{street}\W+
          #{place}\W*\z
        /ix
      end

      # rubocop:disable Lint/MixedRegexpCaptureTypes
      def number
        # Utah and Wisconsin have a more elaborate system of block numbering
        # http://en.wikipedia.org/wiki/House_number#Block_numbers
        @number ||= /(?<number>(n|s|e|w)?\d+[.-]?\d*)(?=\D)/ix
      end
      # rubocop:enable Lint/MixedRegexpCaptureTypes

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
        @street ||= /(?:
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

      def street_type
        @street_type ||= begin
          values = (list.street_types.keys + list.street_types.values).uniq
          ::Regexp.new(values.join('|'), ::Regexp::IGNORECASE)
        end
      end

      def subdivision
        @subdivision ||= begin
          values = list.subdivision_codes.flatten.map { |code| ::Regexp.quote(code) }
          ::Regexp.new("\b#{values.join('|')}\b", ::Regexp::IGNORECASE)
        end
      end

      def unit
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
        @unit_numbered ||= begin
          values = list.unit_abbr_numbered_regexps.values
          /(?<unit_prefix>#{values.join('|')})(?![a-z])/ix
        end
      end

      def unit_unnumbered
        @unit_unnumbered ||= begin
          values = list.unit_abbr_unnumbered_regexps.values
          /(?<unit_prefix>#{values.join('|')})\b/ix
        end
      end

    end
  end
end
