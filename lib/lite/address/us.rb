# frozen_string_literal: true

require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class US

      CARDINAL_TYPES = YAML.load_file(
        File.expand_path('maps/cardinal_types.yml', File.dirname(__FILE__))
      ).freeze
      CARDINAL_CODES = CARDINAL_TYPES.invert.freeze

      STREET_TYPES = YAML.load_file(
        File.expand_path('maps/street_types.yml', File.dirname(__FILE__))
      ).freeze
      STREET_TYPES_LIST = STREET_TYPES.each_with_object({}) do |(key, val), hash|
        hash[key] = true
        hash[val] = true
      end.freeze

      STATE_CODES = YAML.load_file(
        File.expand_path('maps/us/states.yml', File.dirname(__FILE__))
      ).freeze
      STATE_NAMES = STATE_CODES.invert.freeze

      STATE_FIPS = YAML.load_file(
        File.expand_path('maps/us/fips.yml', File.dirname(__FILE__))
      ).freeze
      FIPS_STATES = STATE_FIPS.invert.freeze

      NORMALIZE_MAP = {
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

      class << self

        attr_accessor(
          :street_type_regexp,
          :street_type_matches,
          :number_regexp,
          :fraction_regexp,
          :state_regexp,
          :city_and_state_regexp,
          :direct_regexp,
          :zip_regexp,
          :corner_regexp,
          :unit_regexp,
          :street_regexp,
          :place_regexp,
          :address_regexp,
          :informal_address_regexp,
          :dircode_regexp,
          :unit_prefix_numbered_regexp,
          :unit_prefix_unnumbered_regexp,
          :unit_regexp,
          :sep_regexp,
          :sep_avoid_unit_regexp,
          :intersection_regexp
        )

      end

      self.street_type_matches = {}
      STREET_TYPES.each_pair do |type, abbrv|
        street_type_matches[abbrv] = /\b (?: #{abbrv}|#{Regexp.quote(type)} ) \b/ix
      end

      self.street_type_regexp = Regexp.new(STREET_TYPES_LIST.keys.join('|'), Regexp::IGNORECASE)
      self.fraction_regexp = %r{\d+/\d+}
      self.state_regexp = Regexp.new(
        '\b' + STATE_CODES.flatten.map { |code| Regexp.quote(code) }.join('|') + '\b',
        Regexp::IGNORECASE
      )
      self.direct_regexp = Regexp.new(
        (CARDINAL_TYPES.keys +
         CARDINAL_TYPES.values.sort do |a, b|
           b.length <=> a.length
         end.map do |c|
           f = c.gsub(/(\w)/, '\1.')
           [Regexp.quote(f), Regexp.quote(c)]
         end
        ).join('|'),
        Regexp::IGNORECASE
      )
      self.dircode_regexp = Regexp.new(CARDINAL_CODES.keys.join('|'), Regexp::IGNORECASE)
      self.zip_regexp     = /(?:(?<postal_code>\d{5})(?:-?(?<postal_code_ext>\d{4}))?)/
      self.corner_regexp  = /(?:\band\b|\bat\b|&|@)/i

      # we don't include letters in the number regex because we want to
      # treat "42S" as "42 S" (42 South). For example,
      # Utah and Wisconsin have a more elaborate system of block numbering
      # http://en.wikipedia.org/wiki/House_number#Block_numbers
      self.number_regexp = /(?<number>\d+-?\d*)(?=\D)/ix

      # NOTE: that expressions like [^,]+ may scan more than you expect
      self.street_regexp = /
        (?:
          # special case for addresses like 100 South Street
          (?:(?<street> #{direct_regexp})\W+
             (?<street_type> #{street_type_regexp})\b
          )
          |
          (?:(?<prefix> #{direct_regexp})\W+)?
          (?:
            (?<street> [^,]*\d)
            (?:[^\w,]* (?<suffix> #{direct_regexp})\b)
            |
            (?<street> [^,]+)
            (?:[^\w,]+(?<street_type> #{street_type_regexp})\b)
            (?:[^\w,]+(?<suffix> #{direct_regexp})\b)?
            |
            (?<street> [^,]+?)
            (?:[^\w,]+(?<street_type> #{street_type_regexp})\b)?
            (?:[^\w,]+(?<suffix> #{direct_regexp})\b)?
          )
        )
      /ix

      # http://pe.usps.com/text/pub28/pub28c2_003.htm
      # TODO add support for those that don't require a number
      # TODO map to standard names/abbreviations
      self.unit_prefix_numbered_regexp = /
        (?<unit_prefix>
          su?i?te
          |p\W*[om]\W*b(?:ox)?
          |(?:ap|dep)(?:ar)?t(?:me?nt)?
          |ro*m
          |flo*r?
          |uni?t
          |bu?i?ldi?n?g
          |ha?nga?r
          |lo?t
          |pier
          |slip
          |spa?ce?
          |stop
          |tra?i?le?r
          |box)(?![a-z])
      /ix

      self.unit_prefix_unnumbered_regexp = /
        (?<unit_prefix>
          ba?se?me?n?t
          |fro?nt
          |lo?bby
          |lowe?r
          |off?i?ce?
          |pe?n?t?ho?u?s?e?
          |rear
          |side
          |uppe?r
          )\b
      /ix

      self.unit_regexp = /
        (?:
            (?: (?:#{unit_prefix_numbered_regexp} \W*)
                | (?<unit_prefix> \#)\W*
            )
            (?<unit> [\w-]+)
        )
        |
        #{unit_prefix_unnumbered_regexp}
      /ix

      self.city_and_state_regexp = /
        (?:
            (?<city> [^\d,]+?)\W+
            (?<state> #{state_regexp})
        )
      /ix

      self.place_regexp = /
        (?:#{city_and_state_regexp}\W*)? (?:#{zip_regexp})?
      /ix

      self.address_regexp = /
        \A
        [^\w\x23]*    # skip non-word chars except # (eg unit)
        #{number_regexp} \W*
        (?:#{fraction_regexp}\W*)?
        #{street_regexp}\W+
        (?:#{unit_regexp}\W+)?
        #{place_regexp}
        \W*         # require on non-word chars at end
        \z           # right up to end of string
      /ix

      self.sep_regexp = /(?:\W+|\Z)/
      self.sep_avoid_unit_regexp = /(?:[^\#\w]+|\Z)/

      self.informal_address_regexp = /
        \A
        \s*         # skip leading whitespace
        (?:#{unit_regexp} #{sep_regexp})?
        (?:#{number_regexp})? \W*
        (?:#{fraction_regexp} \W*)?
        #{street_regexp} #{sep_avoid_unit_regexp}
        (?:#{unit_regexp} #{sep_regexp})?
        (?:#{place_regexp})?
        # don't require match to reach end of string
      /ix

      self.intersection_regexp = /\A\W*
        #{street_regexp}\W*?
        \s+#{corner_regexp}\s+
  #          (?{ exists $_{$_} and $_{$_.1} = delete $_{$_} for (qw{prefix street type suffix})})
        #{street_regexp}\W+
  #          (?{ exists $_{$_} and $_{$_.2} = delete $_{$_} for (qw{prefix street type suffix})})
        #{place_regexp}
        \W*\z
      /ix

      class << self

        def parse(location, args = {})
          if corner_regexp.match(location)
            parse_intersection(location, args)
          else
            parse_address(location, args) || parse_informal_address(location, args)
          end
        end

        def parse_address(address, args = {})
          return unless match = address_regexp.match(address)

          to_address(match_to_hash(match), args)
        end

        def parse_informal_address(address, args = {})
          return unless match = informal_address_regexp.match(address)

          to_address(match_to_hash(match), args)
        end

        def parse_intersection(intersection, args)
          return unless match = intersection_regexp.match(intersection)

          hash = match_to_hash(match)

          streets = intersection_regexp.named_captures['street'].map do |pos|
            match[pos.to_i]
          end.select { |v| v }
          hash['street']  = streets[0] if streets[0]
          hash['street2'] = streets[1] if streets[1]

          street_types = intersection_regexp.named_captures['street_type'].map do |pos|
            match[pos.to_i]
          end.select { |v| v }
          hash['street_type']  = street_types[0] if street_types[0]
          hash['street_type2'] = street_types[1] if street_types[1]

          if hash['street_type'] &&
             (
               !hash['street_type2'] ||
               (hash['street_type'] == hash['street_type2'])
             )

            type = hash['street_type'].clone
            if type.gsub!(/s\W*$/i, '') && /\A#{street_type_regexp}\z/i =~ type
              hash['street_type'] = hash['street_type2'] = type
            end
          end

          to_address(hash, args)
        end

        private

        def match_to_hash(match)
          hash = {}
          match.names.each { |name| hash[name] = match[name] if match[name] }
          hash
        end

        def to_address(input, args)
          # strip off some punctuation and whitespace
          input.each_value do |string|
            string.strip!
            string.gsub!(/[^\w\s\-\#&]/, '')
          end

          input['redundant_street_type'] = false
          if input['street'] && !input['street_type']
            match = street_regexp.match(input['street'])
            input['street_type'] = match['street_type']
            input['redundant_street_type'] = true
          end

          NORMALIZE_MAP.each_pair do |key, map|
            next unless input[key]

            mapping = map[input[key].downcase]
            input[key] = mapping if mapping
          end

          if args[:avoid_redundant_street_type]
            ['', '1', '2'].each do |suffix|
              street = input["street#{suffix}"]
              type   = input["street_type#{suffix}"]
              next if !street || !type

              type_regexp = street_type_matches[type.downcase] # || fail "No STREET_TYPE_MATCH for #{type}"
              input.delete("street_type#{suffix}") if type_regexp.match(street)
            end
          end

          # attempt to expand CARDINAL_TYPES prefixes on place names
          input['city']&.gsub!(/^(#{dircode_regexp})\s+(?=\S)/) do |match|
            "#{CARDINAL_CODES[match[0].upcase]} "
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
