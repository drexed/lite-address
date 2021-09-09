# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Parser do
  let(:formal) { load_fixtures(:formal) }
  let(:informal) { load_fixtures(:informal) }
  let(:intersectional) { load_fixtures(:intersectional) }
  let(:failures) { load_fixtures(:failures) }
  let(:parseable) { load_fixtures(:parseable) }

  describe '#any' do
    it 'returns correct parsed attributes' do
      formal.merge(informal, intersectional).each do |address, expected|
        addr = described_class.any(address)

        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end

    it 'returns expected failures' do
      failures.each do |address|
        addr = described_class.any(address)

        expect(!addr || !addr.state).to be_truthy, "failed: #{address.inspect}"
      end
    end
  end

  describe '#formal' do
    it 'returns correct parsed attributes' do
      formal.each do |address, expected|
        addr = described_class.formal(address)

        expect(addr.intersection?).to eq(false)
        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end
  end

  describe '#informal' do
    it 'returns correct parsed attributes' do
      informal.each do |address, expected|
        addr = described_class.informal(address)

        expect(addr.intersection?).to eq(false)
        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end
  end

  describe '#intersectional' do
    it 'returns correct parsed attributes' do
      intersectional.each do |address, expected|
        addr = described_class.intersectional(address)

        expect(addr.intersection?).to eq(true)
        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end
  end

  context 'when parsing specific types' do
    it 'returns nil for road redundant street types' do
      address = '36401 County Road 43, Eaton, CO 80615'
      addr = described_class.any(address, avoid_redundant_street_type: true)
      expected = {
        number: '36401',
        street: 'County Road 43',
        city: 'Eaton',
        state: 'CO',
        postal_code: '80615',
        street_type: nil
      }

      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end

    it 'returns postal code + 4 with dash' do
      addr = described_class.any('2730 S Veitch St, Arlington, VA 22206-3333')

      expect(addr.postal_code_ext).to eq('3333')
    end

    it 'returns postal code + 4 without dash' do
      addr = described_class.any('2730 S Veitch St, Arlington, VA 222064444')

      expect(addr.postal_code_ext).to eq('4444')
    end

    it 'returns correct attributes for full address' do
      address = '2730 S Veitch St, Arlington, VA 222064444'
      addr = described_class.any(address, informal: true)
      expected = {
        number: '2730',
        prefix: 'S',
        street: 'Veitch',
        city: 'Arlington',
        state: 'VA',
        postal_code: '22206',
        postal_code_ext: '4444',
        street_type: 'St'
      }

      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end

    it 'returns correct attributes for partial address' do
      address = '2730 S Veitch St'
      addr = described_class.any(address, informal: true)
      expected = {
        number: '2730',
        prefix: 'S',
        street: 'Veitch',
        street_type: 'St'
      }

      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end

    it 'returns returns correct attributes for address with trailing words' do
      address = '2730 S Veitch St in the south of arlington'
      addr = described_class.any(address, informal: true)
      expected = {
        number: '2730',
        prefix: 'S',
        street: 'Veitch',
        street_type: 'St'
      }

      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end

    it 'returns parsing without issue' do
      parseable.each do |location|
        addr = described_class.any(location)

        expect(addr).not_to eq(nil)
      end
    end

    it 'returns parsing with issue' do
      expect(described_class.any('&')).to eq(nil)
      expect(described_class.any(' and ')).to eq(nil)
    end
  end

  def load_fixtures(file_name)
    file_path = "../../support/fixtures/parser/#{file_name}.yml"
    file_path = File.expand_path(file_path, File.dirname(__FILE__))
    YAML.load_file(file_path)
  end

  def compare_expected_to_actual_hash(expected, actual, address)
    expected.each do |ekey, eval|
      aval = actual[ekey]
      fmsg = "failed #{ekey}: #{address.inspect} due to #{eval.inspect} != #{aval.inspect}"
      expect(eval).to eq(aval), fmsg
    end
  end
end
