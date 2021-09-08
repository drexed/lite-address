# frozen_string_literal: true

require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class US

      # NOTE: List constants

      CARDINAL_TYPES = YAML.load_file(
        File.expand_path('maps/cardinal_types.yml', File.dirname(__FILE__))
      ).freeze
      CARDINAL_CODES = CARDINAL_TYPES.invert.freeze

      STREET_TYPES = YAML.load_file(
        File.expand_path('maps/street_types.yml', File.dirname(__FILE__))
      ).freeze

      STATE_CODES = YAML.load_file(
        File.expand_path('maps/us/states.yml', File.dirname(__FILE__))
      ).freeze
      STATE_NAMES = STATE_CODES.invert.freeze

      STATE_FIPS = YAML.load_file(
        File.expand_path('maps/us/fips.yml', File.dirname(__FILE__))
      ).freeze
      FIPS_STATES = STATE_FIPS.invert.freeze

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
      FRACTION_REGEXP = %r{\d+/\d+}
      SEP_AVOID_UNIT_REGEXP = /(?:[^\#\w]+|\Z)/
      SEP_REGEXP = /(?:\W+|\Z)/
      ZIP_REGEXP = /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/

      # we don't include letters in the number regex because we want to
      # treat "42S" as "42 S" (42 South). For example,
      # Utah and Wisconsin have a more elaborate system of block numbering
      # http://en.wikipedia.org/wiki/House_number#Block_numbers
      NUMBER_REGEXP = /(?<number>\d+-?\d*)(?=\D)/ix

      # http://pe.usps.com/text/pub28/pub28c2_003.htm
      # TODO add support for those that don't require a number
      # TODO map to standard names/abbreviations
      UNIT_PREFIX_NUMBERED_REGEXP = /(?<unit_prefix>
        su?i?te|p\W*[om]\W*b(?:ox)?|(?:ap|dep)(?:ar)?t(?:me?nt)?|ro*m|flo*r?|uni?t|bu?i?ldi?n?g
        |ha?nga?r|lo?t|pier|slip|spa?ce?|stop|tra?i?le?r|box
      )(?![a-z])/ix
      UNIT_PREFIX_UNNUMBERED_REGEXP = /(?<unit_prefix>
        ba?se?me?n?t|fro?nt|lo?bby|lowe?r|off?i?ce?|pe?n?t?ho?u?s?e?|rear|side|uppe?r
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
      UNIT_REGEXP = /
        (?:
          (?:
            (?:#{UNIT_PREFIX_NUMBERED_REGEXP} \W*)
            | (?<unit_prefix> \#)\W*
          )
          (?<unit> [\w-]+)
        ) | #{UNIT_PREFIX_UNNUMBERED_REGEXP}
      /ix
      INTERSECTION_REGEXP = /\A\W*
        #{STREET_REGEXP}\W*?
        \s+#{CORNER_REGEXP}\s+
        #{STREET_REGEXP}\W+
        #{PLACE_REGEXP}
        \W*\z
      /ix
      INFORMAL_ADDRESS_REGEXP = /
        \A
        \s*
        (?:#{UNIT_REGEXP} #{SEP_REGEXP})?
        (?:#{NUMBER_REGEXP})? \W*
        (?:#{FRACTION_REGEXP} \W*)?
        #{STREET_REGEXP} #{SEP_AVOID_UNIT_REGEXP}
        (?:#{UNIT_REGEXP} #{SEP_REGEXP})?
        (?:#{PLACE_REGEXP})?
      /ix
      ADDRESS_REGEXP = /
        \A
        [^\w\x23]* # skip non-word chars except # (eg unit)
        #{NUMBER_REGEXP} \W*
        (?:#{FRACTION_REGEXP}\W*)?
        #{STREET_REGEXP}\W+
        (?:#{UNIT_REGEXP}\W+)?
        #{PLACE_REGEXP}
        \W* # require on non-word chars at end
        \z  # right up to end of string
      /ix

      class << self

        def parse(location, args = {})
          return parse_intersection(location, args) if CORNER_REGEXP.match(location)

          parse_address(location, args) || parse_informal_address(location, args)
        end

        def parse_address(address, args = {})
          return unless match = ADDRESS_REGEXP.match(address)

          to_address(match_to_hash(match), args)
        end

        def parse_informal_address(address, args = {})
          return unless match = INFORMAL_ADDRESS_REGEXP.match(address)

          to_address(match_to_hash(match), args)
        end

        def parse_intersection(intersection, args)
          return unless match = INTERSECTION_REGEXP.match(intersection)

          hash = match_to_hash(match)
          intersection_parts(match, hash, 'street')
          intersection_parts(match, hash, 'street_type')

          if hash['street_type'] && (!hash['street_type2'] || (hash['street_type'] == hash['street_type2']))
            type = hash['street_type'].dup

            if type.gsub!(/s\W*$/i, '') && (/\A#{STREET_TYPE_REGEXP}\z/io =~ type)
              hash['street_type'] = hash['street_type2'] = type
            end
          end

          to_address(hash, args)
        end

        private

        def match_to_hash(match)
          match.names.each_with_object({}) do |name, hash|
            value = match[name]
            next unless value

            hash[name] = value
          end
        end

        def intersection_parts(match, hash, part)
          parts = INTERSECTION_REGEXP.named_captures[part].map { |i| match[i.to_i] }.compact
          hash[part] = parts[0] if parts[0]
          hash["#{part}2"] = parts[1] if parts[1]
        end

        def to_address(input, args)
          # strip off some punctuation and whitespace
          input.each do |key, string|
            string.strip!

            if key == 'street'
              string.gsub!(%r{[^\w\s\-\#&/]}, '')
            else
              string.gsub!(/[^\w\s\-\#&]/, '')
            end
          end

          input['redundant_street_type'] = false
          if input['street'] && !input['street_type']
            match = STREET_REGEXP.match(input['street'])
            input['street_type'] = match['street_type']
            input['redundant_street_type'] = true
          end

          NORMALIZATION_MAP.each_pair do |key, map|
            next unless input[key]

            mapping = map[input[key].downcase]
            input[key] = mapping if mapping
          end

          if args[:avoid_redundant_street_type]
            ['', '1', '2'].each do |suffix|
              street = input["street#{suffix}"]
              street_type = input["street_type#{suffix}"]
              next if !street || !street_type

              type_regexp = STREET_TYPE_MATCHES[street_type.downcase]
              input.delete("street_type#{suffix}") if type_regexp.match(street)
            end
          end

          # attempt to expand CARDINAL_TYPES prefixes on place names
          input['city']&.gsub!(/^(#{CARDINAL_CODE_REGEXP})\s+(?=\S)/o) do |match|
            "#{CARDINAL_CODES[match[0].upcase]} "
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

      end

    end
  end
end
