# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Format do
  let(:addresses) { load_fixtures(:addresses) }
  let(:informal) { load_fixtures(:informal) }
  let(:intersectional) { load_fixtures(:intersectional) }

  describe '#any' do
    it 'returns correct format attributes' do
      addresses.each do |address, expected|
        addr = Lite::Address::Parser.any(address)
        expected[:to_s] ||= fallback_expected_line(expected)

        expect(addr.line1).to eq(expected[:line1])
        expect(addr.line2).to eq(expected[:line2])
        expect(addr.to_s).to eq(expected[:to_s])
      end
    end
  end

  describe '#formal' do
    it 'returns correct format attributes' do
      addresses.each do |address, expected|
        addr = Lite::Address::Parser.formal(address)
        expected[:to_s] ||= fallback_expected_line(expected)

        expect(addr.line1).to eq(expected[:line1])
        expect(addr.line2).to eq(expected[:line2])
        expect(addr.to_s).to eq(expected[:to_s])
      end
    end
  end

  describe '#informal' do
    it 'returns correct format attributes' do
      informal.each do |address, expected|
        addr = Lite::Address::Parser.informal(address)
        expected[:to_s] ||= fallback_expected_line(expected)

        expect(addr.line1).to eq(expected[:line1])
        expect(addr.line2).to eq(expected[:line2])
        expect(addr.to_s).to eq(expected[:to_s])
      end
    end
  end

  describe '#intersectional' do
    it 'returns correct format attributes' do
      intersectional.each do |address, expected|
        addr = Lite::Address::Parser.intersectional(address)
        expected[:to_s] ||= fallback_expected_line(expected)

        expect(addr.line1).to eq(expected[:line1])
        expect(addr.line2).to eq(expected[:line2])
        expect(addr.to_s).to eq(expected[:to_s])
      end
    end
  end

  describe '.full_postal_code' do
    it 'returns 9 digits' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.full_postal_code).to eq('95472-1234')
    end

    it 'returns 5 digits' do
      address = '7800 Mill Station Rd Sebastopol CA 95472'
      addr = Lite::Address::Parser.any(address)

      expect(addr.full_postal_code).to eq('95472')
    end

    it 'returns nil' do
      address = '7800 Mill Station Rd Sebastopol CA'
      addr = Lite::Address::Parser.any(address)

      expect(addr.full_postal_code).to be_nil
    end
  end

  describe '.to_s' do
    it 'returns with no line2' do
      address = '45 Quaker Ave, Ste 105'
      addr = Lite::Address::Parser.any(address)

      expect(addr.to_s).to eq('45 Quaker Ave Suite 105')
    end

    it 'returns with valid addresses with postal_code ext' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.to_s).to eq('7800 Mill Station Rd, Sebastopol, CA 95472-1234')
    end

    it 'returns for line1' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.line1).to eq(addr.to_s(:line1))
    end

    it 'returns for line2' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.line2).to eq(addr.to_s(:line2))
    end
  end

  def load_fixtures(file_name)
    file_path = "../../support/fixtures/format/#{file_name}.yml"
    file_path = File.expand_path(file_path, File.dirname(__FILE__))
    YAML.load_file(file_path)
  end

  def fallback_expected_line(expected)
    [expected[:line1], expected[:line2]].reject(&:empty?).join(', ')
  end
end
