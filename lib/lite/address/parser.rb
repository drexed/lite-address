# frozen_string_literal: true

require 'countries' unless defined?(ISO3166::Country)

module Lite
  module Address
    class Parser

      attr_reader :address, :country_code

      def initialize(address, country_code: 'US')
        @address = sanitize_address(address)
        @country_code = sanitize_country_code(country_code)
      end

      class << self

        def parse(passed_address, args = {})
          instance = new(passed_address, country_code: args.delete(:country_code) || 'US')
          instance.parse(args)
        end

      end

      def parse(args = {})
        return parse_intersectional_address(args) if regexp.corner.match(address)

        parse_formal_address(args) || parse_informal_address(args)
      end

      def parse_formal_address(args = {})
        return unless match = regexp.formal_address.match(address)

        map = match_map(match)
        generate_address(map, args)
      end

      def parse_informal_address(args = {})
        return unless match = regexp.informal_address.match(address)

        map = match_map(match)
        generate_address(map, args)
      end

      def parse_intersectional_address(args = {})
        return unless match = regexp.intersectional_address.match(address)

        map = match_map(match)
        intersectional_submatch(match, map, 'street')
        intersectional_submatch(match, map, 'street_type')
        intersectional_rematch(match, map, 'street_type')

        generate_address(map, args)
      end

      protected

      def country
        @country ||= ISO3166::Country.new(country_code)
      end

      def regexp
        @regexp ||= Lite::Address::Regexp.new(country)
      end

      private

      def sanitize_address(value)
        value.delete_prefix('(').delete_suffix(')')
      end

      def sanitize_country_code(value)
        value.to_s.upcase
      end

      def match_map(match)
        match.names.each_with_object({}) do |name, hash|
          hash[name] = match[name] if match[name]
        end
      end

      def intersectional_submatch(match, map, part)
        parts = regexp.intersectional_address.named_captures
        parts = parts[part].map { |i| match[i.to_i] }.compact
        map[part] = parts[0] if parts[0]
        map["#{part}2"] = parts[1] if parts[1]
      end

      def intersectional_rematch(match, map, part)
        return unless map[part] && (!map["#{part}2"] || (map[part] == map["#{part}2"]))

        type = map[part].dup
        return unless type.gsub!(/s\W*$/i, '') && (/\A#{regexp.send(part)}\z/io =~ type)

        map[part] = map["#{part}2"] = type
      end

      def address_strip_chars(map)
        map.each do |key, string|
          string.strip!

          if key == 'number'
            string.gsub!(%r{[^\w\s\-\#&/.]}, '')
          else
            string.gsub!(%r{[^\w\s\-\#&/]}, '')
          end
        end
      end

      def address_redundantize_street_type(map)
        map['redundant_street_type'] = false

        if map['street'] && !map['street_type']
          match = regexp.street.match(map['street'])
          map['street_type'] = match['street_type'] if match
          map['redundant_street_type'] = true
        end
      end

      def address_abbreviate_unit_prefixes(map)
        regexp.unit_abbreviations.each do |regex, abbr|
          regex.match(map['unit_prefix']) do |_match|
            map['unit_prefix'] = abbr
          end
        end
      end

      def address_normalize_values(map)
        regexp.normalization_map.each do |key, hash|
          next unless map_key = map[key]

          mapping = hash[map_key.downcase]
          map[key] = mapping if mapping
        end
      end

      def address_avoid_redundant_street_type(map)
        ['', '1', '2'].each do |suffix|
          street = map["street#{suffix}"]
          street_type = map["street_type#{suffix}"]
          next if !street || !street_type

          type_regexp = regexp.street_type_matchers[street_type.downcase]
          map.delete("street_type#{suffix}") if type_regexp.match(street)
        end
      end

      def address_expand_cardinals(map)
        map['city']&.gsub!(/^(#{regexp.cardinal_code})\s+(?=\S)/o) do |match|
          "#{regexp.cardinal_codes[match[0].upcase]} "
        end
      end

      def address_fix_dirty_ordinals(map)
        # Sometimes parcel data will have addresses like
        # "1 1ST ST" as "1 1 ST ST"
        map['street']&.gsub!(/\A(\d+\s+st|\d+\s+nd|\d+\s+rd|\d+\s+th)\z/i) do |_match|
          map['street'].gsub(/\s+/, '')
        end
      end

      def address_normalize_parts(map)
        %w[street street_type street2 street_type2 city unit_prefix].each do |k|
          map[k] = map[k].split.map(&:capitalize).join(' ') if map[k]
        end
      end

      def generate_address(map, args = {})
        address_strip_chars(map)
        address_redundantize_street_type(map)
        address_abbreviate_unit_prefixes(map)
        address_normalize_values(map)
        address_avoid_redundant_street_type(map) if args[:avoid_redundant_street_type]
        address_expand_cardinals(map)
        address_fix_dirty_ordinals(map)
        address_normalize_parts(map)

        Lite::Address::Details.new(map)
      end

    end
  end
end
