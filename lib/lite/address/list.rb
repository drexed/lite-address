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
        @subdivision_names ||= country.subdivisions.each_with_object({}) do |(code, subdivision), hash|
          hash[subdivision.name.downcase] = code
        end
      end

      def unit_abbreviations
        # http://pe.usps.com/text/pub28/pub28c2_003
        @unit_abbreviations ||= unit_abbreviations_numbered.merge(unit_abbreviations_unnumbered)
      end

      def unit_abbreviations_numbered
        @unit_abbreviations_numbered ||= {
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
        }
      end

      def unit_abbreviations_unnumbered
        @unit_abbreviations_unnumbered ||= {
          /ba?se?me?n?t/i => 'Basement',
          /fro?nt/i => 'Front',
          /lo?bby/i => 'Lobby',
          /lowe?r/i => 'Lower',
          /off?i?ce?/i => 'Office',
          /pe?n?t?ho?u?s?e?/i => 'PH',
          /rear/i => 'Rear',
          /side/i => 'Side',
          /uppe?r/i => 'Upper'
        }
      end

    end
  end
end
