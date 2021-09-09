# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lite::Address::Ukey do

  describe '.generate' do
    it 'returns an MD5 hash' do
      address = '7800 Mill Station Rd Sebastopol CA 95472-1234'

      expect(described_class.generate(address)).to eq('53ebda245e17a43014e8cc1773087af8')
    end
  end

end
