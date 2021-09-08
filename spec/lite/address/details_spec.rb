# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Details do
  let(:addresses) do
    {
      '1005 Gravenstein Hwy 95472' => {
        line1: '1005 Gravenstein Hwy',
        line2: '95472'
      },
      '1005 Gravenstein Hwy, 95472' => {
        line1: '1005 Gravenstein Hwy',
        line2: '95472'
      },
      '1005 Gravenstein Hwy N, 95472' => {
        line1: '1005 Gravenstein Hwy N',
        line2: '95472'
      },
      '1005 Gravenstein Highway North, 95472' => {
        line1: '1005 Gravenstein Hwy N',
        line2: '95472'
      },
      '1005 N Gravenstein Highway, Sebastopol, CA' => {
        line1: '1005 N Gravenstein Hwy',
        line2: 'Sebastopol, CA'
      },
      '1005 N Gravenstein Highway, Suite 500, Sebastopol, CA' => {
        line1: '1005 N Gravenstein Hwy Suite 500',
        line2: 'Sebastopol, CA'
      },
      '1005 N Gravenstein Hwy Suite 500 Sebastopol, CA' => {
        line1: '1005 N Gravenstein Hwy Suite 500',
        line2: 'Sebastopol, CA'
      },
      '1005 N Gravenstein Highway, Sebastopol, CA, 95472' => {
        line1: '1005 N Gravenstein Hwy',
        line2: 'Sebastopol, CA 95472'
      },
      '1005 N Gravenstein Highway Sebastopol CA 95472' => {
        line1: '1005 N Gravenstein Hwy',
        line2: 'Sebastopol, CA 95472'
      },
      '1005 Gravenstein Hwy N Sebastopol CA' => {
        line1: '1005 Gravenstein Hwy N',
        line2: 'Sebastopol, CA'
      },
      '1005 Gravenstein Hwy N, Sebastopol CA' => {
        line1: '1005 Gravenstein Hwy N',
        line2: 'Sebastopol, CA'
      },
      '1005 Gravenstein Hwy, N Sebastopol CA' => {
        line1: '1005 Gravenstein Hwy',
        line2: 'North Sebastopol, CA'
      },
      '1005 Gravenstein Hwy Sebastopol CA' => {
        line1: '1005 Gravenstein Hwy',
        line2: 'Sebastopol, CA'
      },
      '115 Broadway San Francisco CA' => {
        line1: '115 Broadway',
        line2: 'San Francisco, CA'
      },
      '7800 Mill Station Rd, Sebastopol, CA 95472' => {
        line1: '7800 Mill Station Rd',
        line2: 'Sebastopol, CA 95472'
      },
      '7800 Mill Station Rd Sebastopol CA 95472' => {
        line1: '7800 Mill Station Rd',
        line2: 'Sebastopol, CA 95472'
      },
      '1005 State Highway 116 Sebastopol CA 95472' => {
        line1: '1005 State Highway 116',
        line2: 'Sebastopol, CA 95472'
      },
      '1600 Pennsylvania Ave. Washington DC' => {
        line1: '1600 Pennsylvania Ave',
        line2: 'Washington, DC'
      },
      '1600 Pennsylvania Avenue Washington DC' => {
        line1: '1600 Pennsylvania Ave',
        line2: 'Washington, DC'
      },
      '48S 400E, Salt Lake City UT' => {
        line1: '48 S 400 E',
        line2: 'Salt Lake City, UT'
      },
      '550 S 400 E #3206, Salt Lake City UT 84111' => {
        line1: '550 S 400 E # 3206',
        line2: 'Salt Lake City, UT 84111'
      },
      '6641 N 2200 W Apt D304 Park City, UT 84098' => {
        line1: '6641 N 2200 W Apt D304',
        line2: 'Park City, UT 84098'
      },
      '100 South St, Philadelphia, PA' => {
        line1: '100 South St',
        line2: 'Philadelphia, PA'
      },
      '100 S.E. Washington Ave, Minneapolis, MN' => {
        line1: '100 SE Washington Ave',
        line2: 'Minneapolis, MN'
      },
      '3813 1/2 Some Road, Los Angeles, CA' => {
        line1: '3813 Some Rd',
        line2: 'Los Angeles, CA'
      },
      '1 First St, e San Jose CA' => {
        line1: '1 First St',
        line2: 'East San Jose, CA'
      },
      'lt42 99 Some Road, Some City LA' => {
        line1: '99 Some Rd Lt 42',
        line2: 'Some City, LA'
      },
      '36401 County Road 43, Eaton, CO 80615' => {
        line1: '36401 County Road 43',
        line2: 'Eaton, CO 80615'
      },
      '1234 COUNTY HWY 60E, Town, CO 12345' => {
        line1: '1234 County Hwy 60 E',
        line2: 'Town, CO 12345'
      },
      "'45 Quaker Ave, Ste 105'" => {
        line1: '45 Quaker Ave Ste 105',
        line2: ''
      },
      '2730 S Veitch St Apt 207, Arlington, VA 22206' => {
        line1: '2730 S Veitch St Apt 207',
        line2: 'Arlington, VA 22206'
      },
      '2730 S Veitch St #207, Arlington, VA 22206' => {
        line1: '2730 S Veitch St # 207',
        line2: 'Arlington, VA 22206'
      },
      '44 Canal Center Plaza Suite 500, Alexandria, VA 22314' => {
        line1: '44 Canal Center Plz Suite 500',
        line2: 'Alexandria, VA 22314'
      }
    }
  end
  let(:intersections) do
    {
      'Mission & Valencia San Francisco CA' => {
        line1: 'Mission and Valencia',
        line2: 'San Francisco, CA'
      },
      'Mission & Valencia, San Francisco CA' => {
        line1: 'Mission and Valencia',
        line2: 'San Francisco, CA'
      },
      'Mission St and Valencia St San Francisco CA' => {
        line1: 'Mission St and Valencia St',
        line2: 'San Francisco, CA'
      },
      'Hollywood Blvd and Vine St Los Angeles, CA' => {
        line1: 'Hollywood Blvd and Vine St',
        line2: 'Los Angeles, CA'
      },
      'Mission St & Valencia St San Francisco CA' => {
        line1: 'Mission St and Valencia St',
        line2: 'San Francisco, CA'
      },
      'Mission and Valencia Sts San Francisco CA' => {
        line1: 'Mission St and Valencia St',
        line2: 'San Francisco, CA'
      },
      'Mission & Valencia Sts. San Francisco CA' => {
        line1: 'Mission St and Valencia St',
        line2: 'San Francisco, CA'
      },
      'Mission & Valencia Streets San Francisco CA' => {
        line1: 'Mission St and Valencia St',
        line2: 'San Francisco, CA'
      },
      'Mission Avenue and Valencia Street San Francisco CA' => {
        line1: 'Mission Ave and Valencia St',
        line2: 'San Francisco, CA'
      }
    }
  end
  let(:informal_addresses) do
    {
      '#42 233 S Wacker Dr 60606' => {
        line1: '233 S Wacker Dr # 42',
        line2: '60606'
      },
      'Apt. 42, 233 S Wacker Dr 60606' => {
        line1: '233 S Wacker Dr Apt 42',
        line2: '60606'
      },
      '2730 S Veitch St #207' => {
        line1: '2730 S Veitch St # 207',
        line2: ''
      },
      '321 S. Washington' => {
        line1: '321 S Washington',
        line2: ''
      },
      '233 S Wacker Dr lobby 60606' => {
        line1: '233 S Wacker Dr Lobby',
        line2: '60606'
      }
      # FIXME
      # "(233 S Wacker Dr lobby 60606)" => {
      # :line1 => "233 S Wacker Dr Lobby",
      # :line2 => ""}
    }
  end

  describe 'results' do
    it 'returns line1 with valid addresses' do
      addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)

        expect(expected[:line1]).to eq(addr.line1)
      end
    end

    it 'returns line1 with intersections' do
      intersections.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)

        expect(expected[:line1]).to eq(addr.line1)
      end
    end

    it 'returns line1 with informal addresses' do
      informal_addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse_informal_address(address)

        expect(expected[:line1]).to eq(addr.line1)
      end
    end

    it 'returns line2 with valid addresses' do
      addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)

        expect(expected[:line2]).to eq(addr.line2)
      end
    end

    it 'returns line2 with intersections' do
      intersections.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)

        expect(expected[:line2]).to eq(addr.line2)
      end
    end

    it 'returns line2 with informal addresses' do
      informal_addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse_informal_address(address)

        expect(expected[:line2]).to eq(addr.line2)
      end
    end

    it 'returns to s with valid addresses' do
      addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)
        expected_result = expected[:to_s] || fallback_expected_line(expected)

        expect(expected_result).to eq(addr.to_s)
      end
    end

    it 'returns to s with intersections' do
      intersections.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)
        expected_result = expected[:to_s] || fallback_expected_line(expected)

        expect(expected_result).to eq(addr.to_s)
      end
    end

    it 'returns to s with informal addresses' do
      informal_addresses.each_pair do |address, expected|
        addr = Lite::Address::US.parse(address)
        expected_result = expected[:to_s] || fallback_expected_line(expected)

        expect(expected_result).to eq(addr.to_s)
      end
    end

    it 'returns to s with no line2' do
      address = '45 Quaker Ave, Ste 105'
      addr = Lite::Address::US.parse(address)

      expect(addr.to_s).to eq('45 Quaker Ave Ste 105')
    end

    it 'returns to s with valid addresses with zip ext' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::US.parse(address)

      expect(addr.to_s).to eq('7800 Mill Station Rd, Sebastopol, CA 95472-1234')
    end

    it 'returns to s for line1' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::US.parse(address)

      expect(addr.line1).to eq(addr.to_s(:line1))
    end

    it 'returns to s for line2' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::US.parse(address)

      expect(addr.line2).to eq(addr.to_s(:line2))
    end

    it 'returns full postal code' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'
      addr = Lite::Address::US.parse(address)

      expect(addr.full_postal_code).to eq('95472-1234')

      address = '7800 Mill Station Rd Sebastopol CA 95472'
      addr = Lite::Address::US.parse(address)

      expect(addr.full_postal_code).to eq('95472')

      address = '7800 Mill Station Rd Sebastopol CA'
      addr = Lite::Address::US.parse(address)

      expect(addr.full_postal_code).to be_nil
    end
  end

  def fallback_expected_line(expected)
    [
      expected[:line1],
      expected[:line2]
    ].reject(&:empty?).join(', ')
  end
end
