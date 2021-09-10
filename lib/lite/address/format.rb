# frozen_string_literal: true

module Lite
  module Address

    FORMAT_KEYS = %i[
      number
      street street2
      street_type street_type2 redundant_street_type
      unit_prefix unit
      prefix prefix2
      suffix suffix2
      city
      state
      postal_code postal_code_ext
      country list regexp
    ].freeze

    class Format < Struct.new(*FORMAT_KEYS, keyword_init: true)

      def country_code
        country.alpha2
      end

      def country_name
        country.name
      end

      def intersection?
        !!street && !!street2
      end

      def full_postal_code
        return if postal_code.nil?

        @full_postal_code ||= [postal_code, postal_code_ext].compact.join('-')
      end

      def line1(str = +'')
        parts = intersection? ? intersection_line1 : address_line1
        str + parts.compact.join(' ').strip
      end

      def line2(str = +'')
        str += [city, state].compact.join(', ')
        str << " #{full_postal_code}" if postal_code
        str.strip
      end

      def state_name
        list.subdivision_map[state]
      end

      def to_h
        @to_h ||= Lite::Address::FORMAT_KEYS.each_with_object({}) do |key, hash|
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

      def to_snail(prefixes: [], include_country: false)
        prefixes.push(line1, line2)
        prefixes.push(country_name) if include_country
        prefixes.compact.join("\n")
      end

      def to_ukey
        Lite::Address::Ukey.generate(to_s)
      end

      def ==(other)
        to_s == other.to_s
      end

      alias alpha2 country_code
      alias state_code state

      private

      # rubocop:disable Metrics/AbcSize
      def address_line1
        parts = []
        parts << number
        parts << prefix
        parts << street
        parts << street_type unless redundant_street_type
        parts << suffix
        parts << unit_prefix
        # http://pe.usps.gov/cpim/ftp/pubs/Pub28/pub28.pdf pg28
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
      # rubocop:enable Metrics/AbcSize

    end

  end
end
