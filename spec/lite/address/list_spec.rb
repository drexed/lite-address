# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::List do
  let(:country) { ISO3166::Country.new('US') }
  let(:list) { described_class.new(country) }

  {
    cardinal_codes: 'NW',
    cardinal_types: 'northwest',
    street_types: 'annex',
    street_type_regexps: 'anx',
    subdivision_codes: 'NY',
    subdivision_names: 'new york',
    unit_abbr_regexps: 'Apt',
    unit_abbr_numbered_regexps: 'Apt',
    unit_abbr_unnumbered_regexps: 'Front'
  }.each do |method_name, key|
    describe ".#{method_name}" do
      it 'return a hash with correct values' do
        expect(list.public_send(method_name).key?(key)).to eq(true)
      end
    end
  end

end
