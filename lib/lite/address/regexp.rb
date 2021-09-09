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
          values = list.cardinal_types.keys
          list.cardinal_types.values.sort { |a, b| b.size <=> a.size }.map do |c|
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
        @unit_numbered ||= /(?<unit_prefix>#{list.unit_abbreviations_numbered.keys.join('|')})(?![a-z])/ix
      end

      def unit_unnumbered
        @unit_unnumbered ||= /(?<unit_prefix>#{list.unit_abbreviations_unnumbered.keys.join('|')})\b/ix
      end

    end
  end
end
