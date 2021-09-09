# frozen_string_literal: true

require 'digest' unless defined?(Digest)

module Lite
  module Address
    class Ukey

      class << self

        def generate(value)
          result = value.downcase.gsub(/[^0-9a-z]/i, '')
          Digest::MD5.hexdigest(result)
        end

      end

    end
  end
end
