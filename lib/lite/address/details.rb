# frozen_string_literal: true

module Lite
  module Address

    DETAIL_KEYS = %i[
      number street street_type unit unit_prefix suffix prefix city
      state postal_code postal_code_ext street2 street_type2 suffix2
      prefix2 redundant_street_type
    ].freeze

    class Details < Struct.new(*DETAIL_KEYS, keyword_init: true)

      def full_postal_code
        return if postal_code.nil?

        [postal_code, postal_code_ext].compact.join('-')
      end

      def state_name
        Lite::Address::US::STATE_NAMES[state]&.capitalize
      end

      def intersection?
        !!street && !!street2
      end

      def line1(str = String.new)
        parts = intersection? ? intersection_line1 : address_line1
        str + parts.compact.join(' ').strip
      end

      def line2(str = String.new)
        str += [city, state].compact.join(', ')
        str << " #{full_postal_code}" if postal_code
        str.strip
      end

      def to_h
        Lite::Address::DETAIL_KEYS.each_with_object({}) do |key, hash|
          hash[key] = public_send(key)
        end
      end

      def to_s(format = :default)
        case format
        when :line1 then line1
        when :line2 then line2
        else [line1, line2].reject(&:empty?).join(', ')
        end
      end

      def ==(other)
        to_s == other.to_s
      end

      private

      def address_line1
        parts = []
        parts << number
        parts << prefix
        parts << street
        parts << street_type unless redundant_street_type
        parts << suffix
        parts << unit_prefix
        # follow guidelines: http://pe.usps.gov/cpim/ftp/pubs/Pub28/pub28.pdf pg28
        parts << (unit_prefix ? unit : "\# #{unit}") if unit
        parts
      end

      def intersection_line1
        parts = []
        parts << prefix
        parts << street
        parts << street_type
        parts << suffix
        parts << 'and'
        parts << prefix2
        parts << street2
        parts << street_type2
        parts << suffix2
        parts
      end

    end

  end
end
