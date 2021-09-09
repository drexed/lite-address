# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::List do
  let(:country) { ISO3166::Country.new('US') }
  let(:list) { described_class.new(country) }

  describe '.cardinal_codes' do
    it 'return a hash with correct values' do
      expect(list.cardinal_codes.key?('NW')).to eq(true)
    end
  end

  describe '.cardinal_types' do
    it 'return a hash with correct values' do
      expect(list.cardinal_types.key?('northwest')).to eq(true)
    end
  end

  describe '.street_types' do
    it 'return a hash with correct values' do
      expect(list.street_types.key?('annex')).to eq(true)
    end
  end

  describe '.street_type_regexps' do
    it 'return a hash with correct values' do
      expect(list.street_type_regexps.key?('anx')).to eq(true)
    end
  end

  describe '.subdivision_codes' do
    it 'return a hash with correct values' do
      expect(list.subdivision_codes.key?('NY')).to eq(true)
    end
  end

  describe '.subdivision_names' do
    it 'return a hash with correct values' do
      expect(list.subdivision_names.key?('new york')).to eq(true)
    end
  end

  describe '.unit_abbr_regexps' do
    it 'return a hash with correct values' do
      expect(list.unit_abbr_regexps.key?('Apt')).to eq(true)
    end
  end

  describe '.unit_abbr_numbered_regexps' do
    it 'return a hash with correct values' do
      expect(list.unit_abbr_numbered_regexps.key?('Apt')).to eq(true)
    end
  end

  describe '.unit_abbr_unnumbered_regexps' do
    it 'return a hash with correct values' do
      expect(list.unit_abbr_unnumbered_regexps.key?('Front')).to eq(true)
    end
  end


end
