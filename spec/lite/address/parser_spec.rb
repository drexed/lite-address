# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Parser do
  let(:addresses) do
    {
      '1005 Gravenstein Hwy 95472' => {
        number: '1005',
        street: 'Gravenstein',
        postal_code: '95472',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy, 95472' => {
        number: '1005',
        street: 'Gravenstein',
        postal_code: '95472',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy N, 95472' => {
        number: '1005',
        street: 'Gravenstein',
        postal_code: '95472',
        suffix: 'N',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Highway North, 95472' => {
        number: '1005',
        street: 'Gravenstein',
        postal_code: '95472',
        suffix: 'N',
        street_type: 'Hwy'
      },
      '1005 N Gravenstein Highway, Sebastopol, CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        street_type: 'Hwy',
        prefix: 'N'
      },
      '1005 N Gravenstein Highway, Suite 500, Sebastopol, CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        street_type: 'Hwy',
        prefix: 'N',
        unit_prefix: 'Suite',
        unit: '500'
      },
      '1005 N Gravenstein Hwy Suite 500 Sebastopol, CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        street_type: 'Hwy',
        prefix: 'N',
        unit_prefix: 'Suite',
        unit: '500'
      },
      '1005 N Gravenstein Highway, Sebastopol, CA, 95472' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        postal_code: '95472',
        street_type: 'Hwy',
        prefix: 'N'
      },
      '1005 N Gravenstein Highway Sebastopol CA 95472' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        postal_code: '95472',
        street_type: 'Hwy',
        prefix: 'N'
      },
      '1005 Gravenstein Hwy N Sebastopol CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        suffix: 'N',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy N, Sebastopol CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        suffix: 'N',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy, N Sebastopol CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'North Sebastopol',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy, North Sebastopol CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'North Sebastopol',
        street_type: 'Hwy'
      },
      '1005 Gravenstein Hwy Sebastopol CA' => {
        number: '1005',
        street: 'Gravenstein',
        state: 'CA',
        city: 'Sebastopol',
        street_type: 'Hwy'
      },
      '115 Broadway San Francisco CA' => {
        street_type: nil,
        number: '115',
        street: 'Broadway',
        state: 'CA',
        city: 'San Francisco'
      },
      '7800 Mill Station Rd, Sebastopol, CA 95472' => {
        number: '7800',
        street: 'Mill Station',
        state: 'CA',
        city: 'Sebastopol',
        postal_code: '95472',
        street_type: 'Rd'
      },
      '7800 Mill Station Rd Sebastopol CA 95472' => {
        number: '7800',
        street: 'Mill Station',
        state: 'CA',
        city: 'Sebastopol',
        postal_code: '95472',
        street_type: 'Rd'
      },
      '1005 State Highway 116 Sebastopol CA 95472' => {
        number: '1005',
        street: 'State Highway 116',
        state: 'CA',
        city: 'Sebastopol',
        postal_code: '95472',
        street_type: 'Hwy'
      },
      '1600 Pennsylvania Ave. Washington DC' => {
        number: '1600',
        street: 'Pennsylvania',
        state: 'DC',
        city: 'Washington',
        street_type: 'Ave'
      },
      '1600 Pennsylvania Avenue Washington DC' => {
        number: '1600',
        street: 'Pennsylvania',
        state: 'DC',
        city: 'Washington',
        street_type: 'Ave'
      },
      '48S 400E, Salt Lake City UT' => {
        street_type: nil,
        number: '48',
        street: '400',
        state: 'UT',
        city: 'Salt Lake City',
        suffix: 'E',
        prefix: 'S'
      },
      '550 S 400 E #3206, Salt Lake City UT 84111' => {
        number: '550',
        street: '400',
        state: 'UT',
        unit: '3206',
        postal_code: '84111',
        city: 'Salt Lake City',
        suffix: 'E',
        street_type: nil,
        unit_prefix: '#',
        prefix: 'S'
      },
      '6641 N 2200 W Apt D304 Park City, UT 84098' => {
        number: '6641',
        street: '2200',
        state: 'UT',
        unit: 'D304',
        postal_code: '84098',
        city: 'Park City',
        suffix: 'W',
        street_type: nil,
        unit_prefix: 'Apt',
        prefix: 'N'
      },
      '100 South St, Philadelphia, PA' => {
        number: '100',
        street: 'South',
        state: 'PA',
        city: 'Philadelphia',
        street_type: 'St'
      },
      '100 S.E. Washington Ave, Minneapolis, MN' => {
        number: '100',
        street: 'Washington',
        state: 'MN',
        city: 'Minneapolis',
        street_type: 'Ave',
        prefix: 'SE'
      },
      '3813 1/2 Some Road, Los Angeles, CA' => {
        number: '3813',
        street: '1/2 Some',
        state: 'CA',
        city: 'Los Angeles',
        street_type: 'Rd'
      },
      '8225 W 30 1/2 St, St Louis Park, MN' => {
        number: '8225',
        street: '30 1/2',
        state: 'MN',
        city: 'St Louis Park',
        street_type: 'St',
        prefix: 'W'
      },
      '1 First St, e San Jose CA' => { # lower case city direction
        number: '1',
        street: 'First',
        state: 'CA',
        city: 'East San Jose',
        street_type: 'St'
      },
      '123 Maple Rochester, New York' => { # space in state name
        street_type: nil,
        number: '123',
        street: 'Maple',
        state: 'NY',
        city: 'Rochester'
      },
      '123 31 1/2 st Rochester, New York' => {
        street_type: 'St',
        number: '123',
        street: '31 1/2',
        state: 'NY',
        city: 'Rochester'
      },
      '123 1/2 Dayton St Rochester, New York' => {
        street_type: 'St',
        number: '123',
        street: '1/2 Dayton',
        state: 'NY',
        city: 'Rochester'
      },
      '233 S Wacker Dr 60606-6306' => { # zip+4 with hyphen
        number: '233',
        street: 'Wacker',
        postal_code: '60606',
        postal_code_ext: '6306',
        street_type: 'Dr',
        prefix: 'S'
      },
      '233 S Wacker Dr 606066306' => { # zip+4 without hyphen
        number: '233',
        street: 'Wacker',
        postal_code: '60606',
        postal_code_ext: '6306',
        street_type: 'Dr',
        prefix: 'S'
      },
      'lt42 99 Some Road, Some City LA' => { # no space before sec_unit_num
        unit: '42',
        city: 'Some City',
        number: '99',
        street: 'Some',
        unit_prefix: 'Lot',
        street_type: 'Rd',
        state: 'LA'
      },
      '36401 County Road 43, Eaton, CO 80615' => { # numbered County Road
        city: 'Eaton',
        postal_code: '80615',
        number: '36401',
        street: 'County Road 43',
        street_type: 'Rd',
        state: 'CO'
      },
      '1234 COUNTY HWY 60E, Town, CO 12345' => {
        city: 'Town',
        postal_code: '12345',
        number: '1234',
        street: 'County Hwy 60',
        suffix: 'E',
        street_type: 'Hwy',
        state: 'CO'
      },
      "'45 Quaker Ave, Ste 105'" => { # RT#73397
        number: '45',
        street: 'Quaker',
        street_type: 'Ave',
        unit: '105',
        unit_prefix: 'Suite'
      },
      '2730 S Veitch St Apt 207, Arlington, VA 22206' => { #### pre-existing tests from ruby library
        number: '2730',
        postal_code: '22206',
        prefix: 'S',
        state: 'VA',
        street: 'Veitch',
        street_type: 'St',
        unit: '207',
        unit_prefix: 'Apt',
        city: 'Arlington',
        prefix2: nil,
        postal_code_ext: nil
      },
      '44 Canal Center Plaza Suite 500, Alexandria, VA 22314' => {
        number: '44',
        postal_code: '22314',
        prefix: nil,
        state: 'VA',
        street: 'Canal Center',
        street_type: 'Plz',
        unit: '500',
        unit_prefix: 'Suite',
        city: 'Alexandria',
        street2: nil
      },
      '1600 Pennsylvania Ave Washington DC' => {
        number: '1600',
        postal_code: nil,
        prefix: nil,
        state: 'DC',
        street: 'Pennsylvania',
        street_type: 'Ave',
        unit: nil,
        unit_prefix: nil,
        city: 'Washington',
        street2: nil
      },
      '1005 Gravenstein Hwy N, Sebastopol CA 95472' => {
        number: '1005',
        postal_code: '95472',
        prefix: nil,
        state: 'CA',
        street: 'Gravenstein',
        street_type: 'Hwy',
        unit: nil,
        unit_prefix: nil,
        city: 'Sebastopol',
        street2: nil,
        suffix: 'N'
      },
      '2730 S Veitch St #207, Arlington, VA 22206' => {
        number: '2730',
        street: 'Veitch',
        street_type: 'St',
        unit: '207',
        unit_prefix: '#',
        suffix: nil,
        prefix: 'S',
        city: 'Arlington',
        state: 'VA',
        postal_code: '22206',
        postal_code_ext: nil
      },
      '1 1 ST St, e San Jose CA' => { # Addresses with a dirty ordinal indicator
        number: '1',
        street: '1st',
        state: 'CA',
        city: 'East San Jose',
        street_type: 'St'
      },
      '1 2 ND St, e San Jose CA' => {
        number: '1',
        street: '2nd',
        state: 'CA',
        city: 'East San Jose',
        street_type: 'St'
      },
      '1 3 RD St, e San Jose CA' => {
        number: '1',
        street: '3rd',
        state: 'CA',
        city: 'East San Jose',
        street_type: 'St'
      },
      '1 4 TH St, e San Jose CA' => {
        number: '1',
        street: '4th',
        state: 'CA',
        city: 'East San Jose',
        street_type: 'St'
      },
      'W12090 US HIGHWAY 10, Prescott, WI 54021' => { # Wisconsin Grid Address
        number: 'W12090',
        street: 'Us Highway 10',
        street_type: 'Hwy',
        city: 'Prescott',
        state: 'WI',
        postal_code: '54021'
      },
      'N5781 County Rd J, Ellsworth, WI 54011' => { # Redundant street name with Wisconsin Grid Address
        number: 'N5781',
        street: 'County Rd J',
        street_type: 'Rd',
        city: 'Ellsworth',
        state: 'WI',
        postal_code: '54011'
      }
    }
  end
  let(:intersections) do
    {
      'Mission & Valencia San Francisco CA' => {
        street_type: nil,
        street_type2: nil,
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },

      'Mission & Valencia, San Francisco CA' => {
        street_type: nil,
        street_type2: nil,
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Mission St and Valencia St San Francisco CA' => {
        street_type: 'St',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Hollywood Blvd and Vine St Los Angeles, CA' => {
        street_type: 'Blvd',
        street_type2: 'St',
        street: 'Hollywood',
        state: 'CA',
        city: 'Los Angeles',
        street2: 'Vine'
      },
      'Mission St & Valencia St San Francisco CA' => {
        street_type: 'St',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Mission and Valencia Sts San Francisco CA' => {
        street_type: 'St',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Mission & Valencia Sts. San Francisco CA' => {
        street_type: 'St',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Mission & Valencia Streets San Francisco CA' => {
        street_type: 'St',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      },
      'Mission Avenue and Valencia Street San Francisco CA' => {
        street_type: 'Ave',
        street_type2: 'St',
        street: 'Mission',
        state: 'CA',
        city: 'San Francisco',
        street2: 'Valencia'
      }
    }
  end
  let(:informal_addresses) do
    {
      '#42 233 S Wacker Dr 60606' => {
        number: '233',
        postal_code: '60606',
        prefix: 'S',
        state: nil,
        street: 'Wacker',
        street_type: 'Dr',
        unit: '42',
        unit_prefix: '#',
        city: nil,
        street2: nil,
        suffix: nil
      },
      'Apt. 42, 233 S Wacker Dr 60606' => {
        number: '233',
        postal_code: '60606',
        prefix: 'S',
        state: nil,
        street: 'Wacker',
        street_type: 'Dr',
        unit: '42',
        unit_prefix: 'Apt',
        city: nil,
        street2: nil,
        suffix: nil
      },
      '2730 S Veitch St #207' => {
        number: '2730',
        street: 'Veitch',
        street_type: 'St',
        unit: '207',
        unit_prefix: '#',
        suffix: nil,
        prefix: 'S',
        city: nil,
        state: nil,
        postal_code: nil
      },
      '321 S. Washington' => { # RT#82146
        street_type: nil,
        prefix: 'S',
        street: 'Washington',
        number: '321'
      },
      '233 S Wacker Dr lobby 60606' => { # unnumbered secondary unit type
        number: '233',
        street: 'Wacker',
        postal_code: '60606',
        street_type: 'Dr',
        prefix: 'S',
        unit_prefix: 'Lobby'
      },
      '(233 S Wacker Dr lobby 60606)' => { # surrounding punctuation
        number: '233',
        street: 'Wacker',
        postal_code: '60606',
        street_type: 'Dr',
        prefix: 'S',
        unit_prefix: 'Lobby'
      }
      # '(PO Box 1288, Rome, GA, 30165)' => { # PO Box with surronding punctuation
      #   postal_code: '30165',
      #   city: 'Rome',
      #   state: 'GA',
      #   unit_prefix: 'PO Box',
      #   unit: '1288'
      # },
      # 'PO Box 1288, Rome, GA, 30165' => { # PO Box
      #   postal_code: '30165',
      #   city: 'Rome',
      #   state: 'GA',
      #   unit_prefix: 'PO Box',
      #   unit: '1288'
      # },
      # 'PO Box 1288, Rome, GA, 30165-1288' => { # PO Box with Plus 4
      #   postal_code: '30165',
      #   postal_code_ext: '1288',
      #   city: 'Rome',
      #   state: 'GA',
      #   unit_prefix: 'PO Box',
      #   unit: '1288'
      # }
    }
  end
  let(:expected_failures) do
    [
      '1005 N Gravenstein Hwy Sebastopol',
      '1005 N Gravenstein Hwy Sebastopol CZ',
      'Gravenstein Hwy 95472',
      'E1005 Gravenstein Hwy 95472',
      '1005E Gravenstein Hwy 95472'
    ]
  end
  let(:parseable) do
    [
      '1600 Pennsylvania Ave Washington DC 20006',
      '1600 Pennsylvania Ave #400, Washington, DC, 20006',
      '1600 Pennsylvania Ave Washington, DC',
      '1600 Pennsylvania Ave #400 Washington DC',
      '1600 Pennsylvania Ave, 20006',
      '1600 Pennsylvania Ave #400, 20006',
      '1600 Pennsylvania Ave 20006',
      '1600 Pennsylvania Ave #400 20006',
      'Hollywood & Vine, Los Angeles, CA',
      'Hollywood Blvd and Vine St, Los Angeles, CA',
      'Mission Street at Valencia Street, San Francisco, CA',
      'Hollywood & Vine, Los Angeles, CA, 90028',
      'Hollywood Blvd and Vine St, Los Angeles, CA, 90028',
      'Mission Street at Valencia Street, San Francisco, CA, 90028'
    ]
  end

  describe '#parse' do
    it 'returns correct address parsing' do
      addresses.each do |address, expected|
        addr = described_class.any(address)

        expect(addr.intersection?).to eq(false)
        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end

    it 'returns correct informal address parsing' do
      informal_addresses.each do |address, expected|
        addr = described_class.any(address, informal: true)

        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end

    it 'returns correct intersection address parsing' do
      intersections.each do |address, expected|
        addr = described_class.any(address)

        expect(addr.intersection?).to eq(true)
        compare_expected_to_actual_hash(expected, addr.to_h, address)
      end
    end

    it 'returns correct expected failures' do
      expected_failures.each do |address|
        addr = described_class.any(address)

        expect(!addr || !addr.state).to be_truthy, "failed: #{address.inspect}"
      end
    end

    it 'returns correct street type is nil for road redundant street types' do
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

    it 'returns correct zip plus 4 with dash' do
      addr = described_class.any('2730 S Veitch St, Arlington, VA 22206-3333')

      expect(addr.postal_code_ext).to eq('3333')
    end

    it 'returns correct zip plus 4 without dash' do
      addr = described_class.any('2730 S Veitch St, Arlington, VA 222064444')

      expect(addr.postal_code_ext).to eq('4444')
    end

    it 'returns correct informal parse normal address' do
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

    it 'returns correct informal parse informal address' do
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

    it 'returns correct informal parse informal address trailing words' do
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

    it 'returns correct parse' do
      parseable.each do |location|
        addr = described_class.any(location)

        expect(addr).not_to eq(nil)
      end
    end

    it 'returns incorrect parse' do
      expect(described_class.any('&')).to eq(nil)
      expect(described_class.any(' and ')).to eq(nil)
    end
  end

  def compare_expected_to_actual_hash(expected, actual, address)
    expected.each do |ekey, eval|
      aval = actual[ekey]
      fmsg = "failed #{ekey}: #{address.inspect} due to #{eval.inspect} != #{aval.inspect}"
      expect(eval).to eq(aval), fmsg
    end
  end
end
