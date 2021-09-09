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
      SEP_AVOID_UNIT_REGEXP = /(?:[^\#\w]+|\Z)/
      SEP_REGEXP = /(?:\W+|\Z)/
      ZIP_REGEXP = /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/

      # Utah and Wisconsin have a more elaborate system of block numbering
      # http://en.wikipedia.org/wiki/House_number#Block_numbers
      NUMBER_REGEXP = /(?<number>(n|s|e|w)?\d+[\.-]?\d*)(?=\D)/ix

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
      UNIT_REGEXP = /
        (?:
          (?:
            (?:#{UNIT_PREFIX_NUMBERED_REGEXP} \W*)
            | (?<unit_prefix> \#)\W*
          )
          (?<unit> [\w\/-]+)
        ) | #{UNIT_PREFIX_UNNUMBERED_REGEXP}
      /ix
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

      class << self

        def parse(address, args = {})
          location = preclean_address(address)
          return parse_intersection(location, args) if CORNER_REGEXP.match(location)

          parse_address(location, args) || parse_informal_address(location, args)
        end

        def parse_address(address, args = {})
          return unless match = ADDRESS_REGEXP.match(preclean_address(address))

          to_address(match_to_hash(match), args)
        end

        def parse_informal_address(address, args = {})
          return unless match = INFORMAL_ADDRESS_REGEXP.match(preclean_address(address))

          to_address(match_to_hash(match), args)
        end

        def parse_intersection(address, args = {})
          return unless match = INTERSECTION_REGEXP.match(preclean_address(address))

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
          parts = INTERSECTION_REGEXP.named_captures[part].map { |i| match[i.to_i] }.compact
          hash[part] = parts[0] if parts[0]
          hash["#{part}2"] = parts[1] if parts[1]
        end

        def to_address(input, args)
          # strip off some punctuation and whitespace
          input.each do |key, string|
            string.strip!

            case key
            when 'street' then string.gsub!(%r{[^\w\s\-\#&/]}, '')
            when 'number' then string.gsub!(%r{[^\w\s\-\#\&\/\.]}, '')
            else string.gsub!(/[^\w\s\-\#&]/, '')
            end
          end

          input['redundant_street_type'] = false
          if input['street'] && !input['street_type']
            match = STREET_REGEXP.match(input['street'])
            input['street_type'] = match['street_type'] if match
            input['redundant_street_type'] = true
          end

          ## abbreviate unit prefixes
          UNIT_ABBREVIATIONS.each_pair do |regex, abbr|
            regex.match(input['unit_prefix']) { |_m| input['unit_prefix'] = abbr }
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
