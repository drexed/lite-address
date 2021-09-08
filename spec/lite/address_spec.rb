# frozen_string_literal: true

RSpec.describe Lite::Address do
  it 'to be a version number' do
    expect(Lite::Address::VERSION).not_to be nil
  end
end
