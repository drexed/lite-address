# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Format do
  let(:formal) { load_fixtures(:formal) }
  let(:informal) { load_fixtures(:informal) }
  let(:intersectional) { load_fixtures(:intersectional) }

  describe '#any' do
    it 'returns correct format attributes' do
      formal.merge(informal, intersectional).each do |address, expected|
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
      formal.each do |address, expected|
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

  describe '.country_code' do
    it 'returns "US"' do
      address = '7800 Mill Station Rd Sebastopol NY 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.country_code).to eq('US')
    end
  end

  describe '.country_name' do
    it 'returns "United States of America"' do
      address = '7800 Mill Station Rd Sebastopol NY 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.country_name).to eq('United States of America')
    end
  end

  describe '.intersection?' do
    it 'returns true' do
      addr = Lite::Address::Parser.any(intersectional.keys.first)

      expect(addr.intersection?).to eq(true)
    end

    it 'returns false' do
      addr = Lite::Address::Parser.any(formal.keys.first)

      expect(addr.intersection?).to eq(false)
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

  describe '.state_name' do
    it 'returns "New York"' do
      address = '7800 Mill Station Rd Sebastopol NY 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.state_name).to eq('New York')
    end
  end

  describe '.to_h' do
    it 'returns a hash with all attributes' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::Parser.any(address)

      expect(addr.to_h.key?(:city)).to eq(true)
    end
  end

  describe '.to_s' do
    it 'returns with no line2' do
      address = '45 Quaker Ave, Ste 105'
      addr = Lite::Address::Parser.any(address)

      expect(addr.to_s).to eq('45 Quaker Ave Suite 105')
    end

    it 'returns valid address with postal_code ext' do
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

  describe '.to_snail' do
    it 'returns snail mail format' do
      address = '45 Quaker Ave, Ste 105, Queens, New York 33103-3242'
      addr = Lite::Address::Parser.any(address)
      snail_addr = "John Doe\n45 Quaker Ave Suite 105\nQueens NY  33103-3242"

      expect(addr.to_snail(name: 'John Doe')).to eq(snail_addr)
    end
  end

  describe '.==' do
    it 'returns true' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr1 = Lite::Address::Parser.any(address)
      addr2 = Lite::Address::Parser.any(address)

      expect(addr1 == addr2).to eq(true)
    end

    it 'returns false' do
      address = '7800 Milly Station Rd Sebastopol CA 95472-1234'
      addr1 = Lite::Address::Parser.any(address)
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr2 = Lite::Address::Parser.any(address)

      expect(addr1 == addr2).to eq(false)
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
