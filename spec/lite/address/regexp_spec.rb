# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Regexp do
  let(:country) { ISO3166::Country.new('US') }
  let(:list) { Lite::Address::List.new(country) }
  let(:regexp) { described_class.new(list) }

  %i[
    avoid_unit
    cardinal_code
    cardinal_type
    city_state
    corner
    formal_address
    informal_address
    intersectional_address
    number
    place
    postal_code
    separator
    street
    street_type
    subdivision
    unit
    unit_numbered
    unit_unnumbered
  ].each do |method_name|
    describe ".#{method_name}" do
      it 'return a valid regexp' do
        expect(regexp.public_send(method_name).is_a?(Regexp)).to eq(true)
      end
    end
  end

end
