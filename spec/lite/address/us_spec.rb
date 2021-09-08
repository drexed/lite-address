RSpec.describe Lite::Address::US do
  ADDRESSES = {
    "1005 Gravenstein Hwy 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :postal_code => '95472',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy, 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :postal_code => '95472',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy N, 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :postal_code => '95472',
      :suffix => 'N',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Highway North, 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :postal_code => '95472',
      :suffix => 'N',
      :street_type => 'Hwy',
    },
    "1005 N Gravenstein Highway, Sebastopol, CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :street_type => 'Hwy',
      :prefix => 'N'
    },
    "1005 N Gravenstein Highway, Suite 500, Sebastopol, CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :street_type => 'Hwy',
      :prefix => 'N',
      :unit_prefix => 'Suite',
      :unit => '500',
    },
    "1005 N Gravenstein Hwy Suite 500 Sebastopol, CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :street_type => 'Hwy',
      :prefix => 'N',
      :unit_prefix => 'Suite',
      :unit => '500',
    },
    "1005 N Gravenstein Highway, Sebastopol, CA, 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :postal_code => '95472',
      :street_type => 'Hwy',
      :prefix => 'N'
    },
    "1005 N Gravenstein Highway Sebastopol CA 95472" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :postal_code => '95472',
      :street_type => 'Hwy',
      :prefix => 'N'
    },
    "1005 Gravenstein Hwy N Sebastopol CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :suffix => 'N',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy N, Sebastopol CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :suffix => 'N',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy, N Sebastopol CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'North Sebastopol',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy, North Sebastopol CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'North Sebastopol',
      :street_type => 'Hwy',
    },
    "1005 Gravenstein Hwy Sebastopol CA" => {
      :number => '1005',
      :street => 'Gravenstein',
      :state => 'CA',
      :city => 'Sebastopol',
      :street_type => 'Hwy',
    },
    "115 Broadway San Francisco CA" => {
      :street_type => nil,
      :number => '115',
      :street => 'Broadway',
      :state => 'CA',
      :city => 'San Francisco',
    },
    "7800 Mill Station Rd, Sebastopol, CA 95472" => {
      :number => '7800',
      :street => 'Mill Station',
      :state => 'CA',
      :city => 'Sebastopol',
      :postal_code => '95472',
      :street_type => 'Rd',
    },
    "7800 Mill Station Rd Sebastopol CA 95472" => {
      :number => '7800',
      :street => 'Mill Station',
      :state => 'CA',
      :city => 'Sebastopol',
      :postal_code => '95472',
      :street_type => 'Rd',
    },
    "1005 State Highway 116 Sebastopol CA 95472" => {
      :number => '1005',
      :street => 'State Highway 116',
      :state => 'CA',
      :city => 'Sebastopol',
      :postal_code => '95472',
      :street_type => 'Hwy',
    },
    "1600 Pennsylvania Ave. Washington DC" => {
      :number => '1600',
      :street => 'Pennsylvania',
      :state => 'DC',
      :city => 'Washington',
      :street_type => 'Ave',
    },
    "1600 Pennsylvania Avenue Washington DC" => {
      :number => '1600',
      :street => 'Pennsylvania',
      :state => 'DC',
      :city => 'Washington',
      :street_type => 'Ave',
    },
    "48S 400E, Salt Lake City UT" => {
      :street_type => nil,
      :number => '48',
      :street => '400',
      :state => 'UT',
      :city => 'Salt Lake City',
      :suffix => 'E',
      :prefix => 'S'
    },
    "550 S 400 E #3206, Salt Lake City UT 84111" => {
      :number => '550',
      :street => '400',
      :state => 'UT',
      :unit => '3206',
      :postal_code => '84111',
      :city => 'Salt Lake City',
      :suffix => 'E',
      :street_type => nil,
      :unit_prefix => '#',
      :prefix => 'S'
    },
    "6641 N 2200 W Apt D304 Park City, UT 84098" => {
      :number => '6641',
      :street => '2200',
      :state => 'UT',
      :unit => 'D304',
      :postal_code => '84098',
      :city => 'Park City',
      :suffix => 'W',
      :street_type => nil,
      :unit_prefix => 'Apt',
      :prefix => 'N'
    },
    "100 South St, Philadelphia, PA" => {
      :number => '100',
      :street => 'South',
      :state => 'PA',
      :city => 'Philadelphia',
      :street_type => 'St',
    },
    "100 S.E. Washington Ave, Minneapolis, MN" => {
      :number => '100',
      :street => 'Washington',
      :state => 'MN',
      :city => 'Minneapolis',
      :street_type => 'Ave',
      :prefix => 'SE'
    },
    "3813 1/2 Some Road, Los Angeles, CA" => {
      :number => '3813',
      :street => 'Some',
      :state => 'CA',
      :city => 'Los Angeles',
      :street_type => 'Rd',
    },
    "1 First St, e San Jose CA" => { # lower case city direction
      :number => '1',
      :street => 'First',
      :state => 'CA',
      :city => 'East San Jose',
      :street_type => 'St',
    },
    "123 Maple Rochester, New York" => { # space in state name
      :street_type => nil,
      :number => '123',
      :street => 'Maple',
      :state => 'NY',
      :city => 'Rochester',
    },
    "233 S Wacker Dr 60606-6306" => { # zip+4 with hyphen
      :number => '233',
      :street => 'Wacker',
      :postal_code => '60606',
      :postal_code_ext => '6306',
      :street_type => 'Dr',
      :prefix => 'S'
    },
    "233 S Wacker Dr 606066306" => { # zip+4 without hyphen
      :number => '233',
      :street => 'Wacker',
      :postal_code => '60606',
      :postal_code_ext => '6306',
      :street_type => 'Dr',
      :prefix => 'S'
    },
    "lt42 99 Some Road, Some City LA" => { # no space before sec_unit_num
      :unit => '42',
      :city => 'Some City',
      :number => '99',
      :street => 'Some',
      :unit_prefix => 'Lt',
      :street_type => 'Rd',
      :state => 'LA'
    },
    "36401 County Road 43, Eaton, CO 80615" => { # numbered County Road
      :city => 'Eaton',
      :postal_code => '80615',
      :number => '36401',
      :street => 'County Road 43',
      :street_type => 'Rd',
      :state => 'CO'
    },
    "1234 COUNTY HWY 60E, Town, CO 12345" => {
      :city => 'Town',
      :postal_code => '12345',
      :number => '1234',
      :street => 'County Hwy 60',
      :suffix => 'E',
      :street_type => 'Hwy',
      :state => 'CO'
    },
    "'45 Quaker Ave, Ste 105'" => { # RT#73397
      :number => '45',
      :street => 'Quaker',
      :street_type => 'Ave',
      :unit => '105',
      :unit_prefix => 'Ste'
    },
    ##### pre-existing tests from ruby library
    "2730 S Veitch St Apt 207, Arlington, VA 22206" => {
      :number => "2730",
      :postal_code => "22206",
      :prefix => "S",
      :state => "VA",
      :street => "Veitch",
      :street_type => "St",
      :unit => "207",
      :unit_prefix => "Apt",
      :city => "Arlington",
      :prefix2 => nil,
      :postal_code_ext => nil
    },
    "44 Canal Center Plaza Suite 500, Alexandria, VA 22314" => {
      :number => "44",
      :postal_code => "22314",
      :prefix => nil,
      :state => "VA",
      :street => "Canal Center",
      :street_type => "Plz",
      :unit => "500",
      :unit_prefix => "Suite",
      :city => "Alexandria",
      :street2 => nil
    },
    "1600 Pennsylvania Ave Washington DC" => {
      :number => "1600",
      :postal_code => nil,
      :prefix => nil,
      :state => "DC",
      :street => "Pennsylvania",
      :street_type => "Ave",
      :unit => nil,
      :unit_prefix => nil,
      :city => "Washington",
      :street2 => nil
    },
    "1005 Gravenstein Hwy N, Sebastopol CA 95472" => {
      :number => "1005",
      :postal_code => "95472",
      :prefix => nil,
      :state => "CA",
      :street => "Gravenstein",
      :street_type => "Hwy",
      :unit => nil,
      :unit_prefix => nil,
      :city => "Sebastopol",
      :street2 => nil,
      :suffix => "N"
    },
    "2730 S Veitch St #207, Arlington, VA 22206" => {
      :number=>"2730",
      :street=>"Veitch",
      :street_type=>"St",
      :unit=>"207",
      :unit_prefix=>"#",
      :suffix=>nil,
      :prefix=>"S",
      :city=>"Arlington",
      :state=>"VA",
      :postal_code=>"22206",
      :postal_code_ext=>nil
    }
  }

  INTERSECTIONS = {
    "Mission & Valencia San Francisco CA" => {
      :street_type => nil,
      :street_type2 => nil,
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },

    "Mission & Valencia, San Francisco CA" => {
      :street_type => nil,
      :street_type2 => nil,
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Mission St and Valencia St San Francisco CA" => {
      :street_type => 'St',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Hollywood Blvd and Vine St Los Angeles, CA" => {
      :street_type => 'Blvd',
      :street_type2 => 'St',
      :street => 'Hollywood',
      :state => 'CA',
      :city => 'Los Angeles',
      :street2 => 'Vine'
    },
    "Mission St & Valencia St San Francisco CA" => {
      :street_type => 'St',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Mission and Valencia Sts San Francisco CA" => {
      :street_type => 'St',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Mission & Valencia Sts. San Francisco CA" => {
      :street_type => 'St',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Mission & Valencia Streets San Francisco CA" => {
      :street_type => 'St',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    },
    "Mission Avenue and Valencia Street San Francisco CA" => {
      :street_type => 'Ave',
      :street_type2 => 'St',
      :street => 'Mission',
      :state => 'CA',
      :city => 'San Francisco',
      :street2 => 'Valencia'
    }
  }

  INFORMAL_ADDRESSES = {
    "#42 233 S Wacker Dr 60606" => {
      :number => "233",
      :postal_code => "60606",
      :prefix => "S",
      :state => nil,
      :street => "Wacker",
      :street_type => "Dr",
      :unit => "42",
      :unit_prefix => "#",
      :city => nil,
      :street2 => nil,
      :suffix => nil
    },
    "Apt. 42, 233 S Wacker Dr 60606" => {
      :number => "233",
      :postal_code => "60606",
      :prefix => "S",
      :state => nil,
      :street => "Wacker",
      :street_type => "Dr",
      :unit => "42",
      :unit_prefix => "Apt",
      :city => nil,
      :street2 => nil,
      :suffix => nil
    },
    "2730 S Veitch St #207" => {
      :number=>"2730",
      :street=>"Veitch",
      :street_type=>"St",
      :unit=>"207",
      :unit_prefix=>"#",
      :suffix=>nil,
      :prefix=>"S",
      :city=>nil,
      :state=>nil,
      :postal_code=>nil
    },
    "321 S. Washington" => { # RT#82146
      :street_type => nil,
      :prefix => 'S',
      :street => 'Washington',
      :number => '321'
    },
    "233 S Wacker Dr lobby 60606" => { # unnumbered secondary unit type
      :number => '233',
      :street => 'Wacker',
      :postal_code => '60606',
      :street_type => 'Dr',
      :prefix => 'S',
      :unit_prefix => 'Lobby',
    },
    "(233 S Wacker Dr lobby 60606)" => { # surrounding punctuation
      :number => '233',
      :street => 'Wacker',
      :postal_code => '60606',
      :street_type => 'Dr',
      :prefix => 'S',
      :unit_prefix => 'Lobby',
    }
  }

  EXPECTED_FAILURES =  [
    "1005 N Gravenstein Hwy Sebastopol",
    "1005 N Gravenstein Hwy Sebastopol CZ",
    "Gravenstein Hwy 95472",
    "E1005 Gravenstein Hwy 95472",
    # "1005E Gravenstein Hwy 95472"
    ## adding from original ruby test suite
    "PO BOX 450, Chicago IL 60657"
  ]

  it("address parsing") do
    ADDRESSES.each_pair do |address, expected|
      addr = Lite::Address::US.parse(address)
      expect(false).to(eq(addr.intersection?))
      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end
  end

  it("informal address parsing") do
    INFORMAL_ADDRESSES.each_pair do |address, expected|
      addr = Lite::Address::US.parse(address, :informal => true)
      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end
  end

  it("intersection address parsing") do
    INTERSECTIONS.each_pair do |address, expected|
      addr = Lite::Address::US.parse(address)
      expect(true).to(eq(addr.intersection?))
      compare_expected_to_actual_hash(expected, addr.to_h, address)
    end
  end

  it("expected failures") do
    EXPECTED_FAILURES.each do |address|
      parsed_address = Lite::Address::US.parse(address)
      expect(((not parsed_address) or (not parsed_address.state))).to(be_truthy)
    end
  end

  it("street type is nil for road redundant street types") do
    address = "36401 County Road 43, Eaton, CO 80615"
    expected_results = { :number => "36401", :street => "County Road 43", :city => "Eaton", :state => "CO", :postal_code => "80615", :street_type => nil }
    parsed_address = Lite::Address::US.parse(address, :avoid_redundant_street_type => true)
    compare_expected_to_actual_hash(expected_results, parsed_address.to_h, address)
  end

  it("zip plus 4 with dash") do
    addr = Lite::Address::US.parse("2730 S Veitch St, Arlington, VA 22206-3333")
    expect(addr.postal_code_ext).to(eq("3333"))
  end

  it("zip plus 4 without dash") do
    addr = Lite::Address::US.parse("2730 S Veitch St, Arlington, VA 222064444")
    expect(addr.postal_code_ext).to(eq("4444"))
  end

  it("informal parse normal address") do
    a = Lite::Address::US.parse("2730 S Veitch St, Arlington, VA 222064444", :informal => true)
    expect(a.number).to(eq("2730"))
    expect(a.prefix).to(eq("S"))
    expect(a.street).to(eq("Veitch"))
    expect(a.street_type).to(eq("St"))
    expect(a.city).to(eq("Arlington"))
    expect(a.state).to(eq("VA"))
    expect(a.postal_code).to(eq("22206"))
    expect(a.postal_code_ext).to(eq("4444"))
  end

  it("informal parse informal address") do
    a = Lite::Address::US.parse("2730 S Veitch St", :informal => true)
    expect(a.number).to(eq("2730"))
    expect(a.prefix).to(eq("S"))
    expect(a.street).to(eq("Veitch"))
    expect(a.street_type).to(eq("St"))
  end

  it("informal parse informal address trailing words") do
    a = Lite::Address::US.parse("2730 S Veitch St in the south of arlington", :informal => true)
    expect(a.number).to(eq("2730"))
    expect(a.prefix).to(eq("S"))
    expect(a.street).to(eq("Veitch"))
    expect(a.street_type).to(eq("St"))
  end

  it("parse") do
    expect(nil).to(eq(Lite::Address::US.parse("&")))
    expect(nil).to(eq(Lite::Address::US.parse(" and ")))
    parseable = ["1600 Pennsylvania Ave Washington DC 20006", "1600 Pennsylvania Ave #400, Washington, DC, 20006", "1600 Pennsylvania Ave Washington, DC", "1600 Pennsylvania Ave #400 Washington DC", "1600 Pennsylvania Ave, 20006", "1600 Pennsylvania Ave #400, 20006", "1600 Pennsylvania Ave 20006", "1600 Pennsylvania Ave #400 20006", "Hollywood & Vine, Los Angeles, CA", "Hollywood Blvd and Vine St, Los Angeles, CA", "Mission Street at Valencia Street, San Francisco, CA", "Hollywood & Vine, Los Angeles, CA, 90028", "Hollywood Blvd and Vine St, Los Angeles, CA, 90028", "Mission Street at Valencia Street, San Francisco, CA, 90028"]
    parseable.each do |location|
      expect(Lite::Address::US.parse(location)).to(be_truthy)
    end
  end

  it("comparison") do
    addr = Lite::Address::US.parse(ADDRESSES.first[0])
    expect("1005 Gravenstein Hwy, 95472").to(eq(addr.to_s))
    expect(Lite::Address::US.parse(ADDRESSES.first[0])).to(eq(addr))
    expect(Lite::Address::US.parse(EXPECTED_FAILURES.first)).to_not(eq(addr))
    expect(nil).to_not(eq(addr))
  end

  def compare_expected_to_actual_hash(expected, actual, address)
    expected.each_pair do |expected_key, expected_value|
      expect(expected_value).to eq(actual[expected_key])
    end
  end
end
