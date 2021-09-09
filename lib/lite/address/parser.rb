# frozen_string_literal: true

require 'countries' unless defined?(ISO3166::Country)
require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class Parser

      # NOTE: List constants

      CARDINAL_TYPES = YAML.load_file(
        File.expand_path('types/cardinal.yml', File.dirname(__FILE__))
      ).freeze
      CARDINAL_CODES = CARDINAL_TYPES.invert.freeze

      STREET_TYPES = YAML.load_file(
        File.expand_path('types/street.yml', File.dirname(__FILE__))
      ).freeze

      STATE_CODES = ISO3166::Country.new('US').subdivisions.each_with_object({}) do |(code, subdivision), hash|
        hash[subdivision.name.downcase] = code
      end.freeze
      STATE_NAMES = STATE_CODES.invert.freeze

      NORMALIZATION_MAP = {
        'prefix' => CARDINAL_TYPES,
        'prefix1' => CARDINAL_TYPES,
        'prefix2' => CARDINAL_TYPES,
        'suffix' => CARDINAL_TYPES,
        'suffix1' => CARDINAL_TYPES,
        'suffix2' => CARDINAL_TYPES,
        'street_type' => STREET_TYPES,
        'street_type1' => STREET_TYPES,
        'street_type2' => STREET_TYPES,
        'state' => STATE_CODES
      }.freeze

      # NOTE: Static constants

      CORNER_REGEXP = /(?:\band\b|\bat\b|&|@)/i
      SEP_AVOID_UNIT_REGEXP = /(?:[^\#\w]+|\Z)/
      SEP_REGEXP = /(?:\W+|\Z)/
      ZIP_REGEXP = /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/

      # Utah and Wisconsin have a more elaborate system of block numbering
      # http://en.wikipedia.org/wiki/House_number#Block_numbers
      NUMBER_REGEXP = /(?<number>(n|s|e|w)?\d+[.-]?\d*)(?=\D)/ix

      # http://pe.usps.com/text/pub28/pub28c2_003.htm
      UNIT_ABBREVIATIONS_NUMBERED = {
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
      }.freeze
      UNIT_ABBREVIATIONS_UNNUMBERED = {
        /ba?se?me?n?t/i => 'Basement',
        /fro?nt/i => 'Front',
        /lo?bby/i => 'Lobby',
        /lowe?r/i => 'Lower',
        /off?i?ce?/i => 'Office',
        /pe?n?t?ho?u?s?e?/i => 'PH',
        /rear/i => 'Rear',
        /side/i => 'Side',
        /uppe?r/i => 'Upper'
      }.freeze
      UNIT_ABBREVIATIONS = UNIT_ABBREVIATIONS_NUMBERED.merge(
        UNIT_ABBREVIATIONS_UNNUMBERED
      ).freeze
      UNIT_PREFIX_NUMBERED_REGEXP = /(?<unit_prefix>
        #{UNIT_ABBREVIATIONS_NUMBERED.keys.join('|')}
      )(?![a-z])/ix
      UNIT_PREFIX_UNNUMBERED_REGEXP = /(?<unit_prefix>
        #{UNIT_ABBREVIATIONS_UNNUMBERED.keys.join('|')}
      )\b/ix

      # NOTE: Dynamic constants

      CARDINAL_CODE_REGEXP = Regexp.new(
        CARDINAL_CODES.keys.join('|'),
        Regexp::IGNORECASE
      ).freeze
      CARDINAL_TYPE_REGEXP = Regexp.new(
        (
          CARDINAL_TYPES.keys +
          CARDINAL_TYPES.values.sort { |a, b| b.size <=> a.size }.map do |c|
            [Regexp.quote(c.gsub(/(\w)/, '\1.')), Regexp.quote(c)]
          end
        ).join('|'),
        Regexp::IGNORECASE
      ).freeze
      STATE_REGEXP = Regexp.new(
        '\b' + STATE_CODES.flatten.map { |code| Regexp.quote(code) }.join('|') + '\b',
        Regexp::IGNORECASE
      ).freeze
      CITY_AND_STATE_REGEXP = /(?:
        (?<city> [^\d,]+?)\W+(?<state> #{STATE_REGEXP})
      )/ix
      PLACE_REGEXP = /
        (?:#{CITY_AND_STATE_REGEXP}\W*)? (?:#{ZIP_REGEXP})?
      /ix
      STREET_TYPES_LIST = STREET_TYPES.each_with_object({}) do |(key, val), hash|
        hash[key] = true
        hash[val] = true
      end.freeze
      STREET_TYPE_MATCHES = STREET_TYPES.each_with_object({}) do |(type, abbr), hash|
        hash[abbr] = /\b (?: #{abbr}|#{Regexp.quote(type)} ) \b/ix
      end.freeze
      STREET_TYPE_REGEXP = Regexp.new(
        STREET_TYPES_LIST.keys.join('|'),
        Regexp::IGNORECASE
      ).freeze
      STREET_REGEXP = /
        (?:
          # NOTE: that expressions like [^,]+ may scan more than you expect
          # special case for addresses like 100 South Street
          (?:
            (?<street> #{CARDINAL_TYPE_REGEXP})\W+
            (?<street_type> #{STREET_TYPE_REGEXP})\b
          )
          | (?:(?<prefix> #{CARDINAL_TYPE_REGEXP})\W+)?
          (?:
            (?<street> [^,]*\d)
            (?:[^\w,]* (?<suffix> #{CARDINAL_TYPE_REGEXP})\b)
            |
            (?<street> [^,]+)
            (?:[^\w,]+(?<street_type> #{STREET_TYPE_REGEXP})\b)
            (?:[^\w,]+(?<suffix> #{CARDINAL_TYPE_REGEXP})\b)?
            |
            (?<street> [^,]+?)
            (?:[^\w,]+(?<street_type> #{STREET_TYPE_REGEXP})\b)?
            (?:[^\w,]+(?<suffix> #{CARDINAL_TYPE_REGEXP})\b)?
          )
        )
      /ix
      UNIT_REGEXP = %r{
        (?:
          (?:
            (?:#{UNIT_PREFIX_NUMBERED_REGEXP} \W*)
            | (?<unit_prefix> \#)\W*
          )
          (?<unit> [\w/-]+)
        ) | #{UNIT_PREFIX_UNNUMBERED_REGEXP}
      }ix
      INTERSECTION_REGEXP = /\A\W*
        #{STREET_REGEXP}\W*?
        \s+#{CORNER_REGEXP}\s+
        # (?{ exists $_{$_} and $_{$_.1} = delete $_{$_} for (qw{prefix street type suffix})})
        #{STREET_REGEXP}\W+
        # (?{ exists $_{$_} and $_{$_.2} = delete $_{$_} for (qw{prefix street type suffix})})
        #{PLACE_REGEXP}
        \W*\z
      /ix
      INFORMAL_ADDRESS_REGEXP = /
        \A
        \s*
        (?:#{UNIT_REGEXP} #{SEP_REGEXP} #{PLACE_REGEXP})?
        (?:#{NUMBER_REGEXP})? \W*
        #{STREET_REGEXP} #{SEP_AVOID_UNIT_REGEXP}
        (?:#{UNIT_REGEXP} #{SEP_REGEXP})?
        (?:#{PLACE_REGEXP})?
      /ix
      ADDRESS_REGEXP = /
        \A
        [^\w\x23]* # skip non-word chars except # (eg unit)
        #{NUMBER_REGEXP} \W*
        #{STREET_REGEXP}\W+
        (?:#{UNIT_REGEXP}\W+)?
        #{PLACE_REGEXP}
        \W* # require on non-word chars at end
        \z  # right up to end of string
      /ix















      attr_reader :address, :country_code

      def initialize(address, country_code: 'US')
        @address = sanitize_address(address)
        @country_code = sanitize_country_code(country_code)
      end

      class << self

        def call(passed_address, args = {})
          instance = new(passed_address, country_code: args.delete(:country_code) || 'US')
          instance.call(args)
        end

      end

      def call(args = {})
        return parse_intersectional_address(args) if CORNER_REGEXP.match(address)

        parse_formal_address(args) || parse_informal_address(args)
      end

      def parse_formal_address(args = {})
        return unless match = ADDRESS_REGEXP.match(address)

        map = match_map(match)
        generate_address(map, args)
      end

      def parse_informal_address(args = {})
        return unless match = INFORMAL_ADDRESS_REGEXP.match(address)

        map = match_map(match)
        generate_address(map, args)
      end

      def parse_intersectional_address(args = {})
        return unless match = INTERSECTION_REGEXP.match(address)

        map = match_map(match)
        intersectional_submatch(match, map, 'street')
        intersectional_submatch(match, map, 'street_type')
        intersectional_rematch(match, map, 'street_type')

        generate_address(map, args)
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
        parts = INTERSECTION_REGEXP.named_captures[part].map { |i| match[i.to_i] }.compact
        map[part] = parts[0] if parts[0]
        map["#{part}2"] = parts[1] if parts[1]
      end

      def intersectional_rematch(match, map, part)
        return unless map[part] && (!map["#{part}2"] || (map[part] == map["#{part}2"]))

        type = map[part].dup
        # TODO: convert regexp to use send("regexp_#{part}")
        return unless type.gsub!(/s\W*$/i, '') && (/\A#{STREET_TYPE_REGEXP}\z/io =~ type)

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
          match = STREET_REGEXP.match(map['street'])
          map['street_type'] = match['street_type'] if match
          map['redundant_street_type'] = true
        end
      end

      def address_abbreviate_unit_prefixes(map)
        UNIT_ABBREVIATIONS.each_pair do |regex, abbr|
          regex.match(map['unit_prefix']) { |_m| map['unit_prefix'] = abbr }
        end
      end

      def address_normalize_values(map)
        NORMALIZATION_MAP.each do |key, hash|
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

          type_regexp = STREET_TYPE_MATCHES[street_type.downcase]
          map.delete("street_type#{suffix}") if type_regexp.match(street)
        end
      end

      def address_expand_cardinals(map)
        map['city']&.gsub!(/^(#{CARDINAL_CODE_REGEXP})\s+(?=\S)/o) do |match|
          "#{CARDINAL_CODES[match[0].upcase]} "
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
