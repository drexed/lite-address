# frozen_string_literal: true

require 'yaml' unless defined?(YAML)

module Lite
  module Address
    class List

      attr_reader :country

      def initialize(country)
        @country = country
      end

      def cardinal_codes
        @cardinal_codes ||= cardinal_types.invert
      end

      def cardinal_types
        @cardinal_types ||= begin
          file_path = File.expand_path('types/cardinal.yml', File.dirname(__FILE__))
          YAML.load_file(file_path)
        end
      end

      def street_types
        @street_types ||= begin
          file_path = File.expand_path('types/street.yml', File.dirname(__FILE__))
          YAML.load_file(file_path)
        end
      end

      def street_type_regexps
        @street_type_regexps ||= street_types.each_with_object({}) do |(type, abbr), hash|
          hash[abbr] = /\b(?:#{abbr}|#{::Regexp.quote(type)})\b/ix
        end
      end

      def subdivision_codes
        @subdivision_codes ||= subdivision_names.invert
      end

      def subdivision_names
        @subdivision_names ||= country.subdivisions.each_with_object({}) do |(code, sub), hash|
          hash[sub.name.downcase] = code
        end
      end

      def unit_abbr_regexps
        # http://pe.usps.com/text/pub28/pub28c2_003
        @unit_abbr_regexps ||= unit_abbr_numbered_regexps.merge(unit_abbr_unnumbered_regexps)
      end

      # rubocop:disable Metrics/MethodLength
      def unit_abbr_numbered_regexps
        @unit_abbr_numbered_regexps ||= {
          'Apt' => /(?:ap|dep)(?:ar)?t(?:me?nt)?/i,
          'PO Box' => /p\W*[om]\W*b(?:ox)?/i,
          'Bldg' => /bu?i?ldi?n?g/i,
          'Dept' => /dep(artmen)?t/i,
          'Floor' => /flo*r?/i,
          'Hanger' => /ha?nga?r/i,
          'Lot' => /lo?t/i,
          'Room' => /ro*m/i,
          'Pier' => /pier/i,
          'Slip' => /slip/i,
          'Space' => /spa?ce?/i,
          'Stop' => /stop/i,
          'Drawer' => /drawer/i,
          'Suite' => /su?i?te/i,
          'Trailer' => /tra?i?le?r/i,
          'Box' => /\w*(?<!po\W)box/i,
          'Unit' => /uni?t/i
        }
      end

      def unit_abbr_unnumbered_regexps
        @unit_abbr_unnumbered_regexps ||= {
          'Basement' => /ba?se?me?n?t/i,
          'Front' => /fro?nt/i,
          'Lobby' => /lo?bby/i,
          'Lower' => /lowe?r/i,
          'Office' => /off?i?ce?/i,
          'PH' => /pe?n?t?ho?u?s?e?/i,
          'Rear' => /rear/i,
          'Side' => /side/i,
          'Upper' => /uppe?r/i
        }
      end
      # rubocop:enable Metrics/MethodLength

      alias state_codes subdivision_codes
      alias state_names subdivision_names

    end
  end
end
