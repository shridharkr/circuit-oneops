require 'spec_helper'

require File.expand_path('../../../../libraries/models/address.rb', __FILE__)

describe 'Address' do
  context 'name' do
    it 'succeeds when not nil' do
      address = Address.new('name', 'FQDN', '1.1.1.1')
      expect(address).to be_a Address
    end

    it 'fails when nil' do
      expect{Address.new(nil, 'FQDN', '1.1.1.1')}.to raise_error(ArgumentError)
    end
  end

  context 'type' do
    it 'fails when nil' do
      expect{Address.new('name', nil, '1.1.1.1')}.to raise_error(ArgumentError)
    end

    it 'is valid' do
      %w(IP_NETMASK IP_RANGE FQDN).each do |type|
        address = Address.new('name', type, '1.1.1.1')
        expect(address.type).to be == type
      end
    end

    it 'fails when not valid' do
      %w(OH_MAN DANG_IT FAIL).each do |type|
        expect{Address.new('name', type, '1.1.1.1')}.to raise_error(ArgumentError)
      end
    end
  end

  context 'ip address' do
    it 'fails when nil' do
      expect{Address.new('name', 'FQDN', nil)}.to raise_error(ArgumentError)
    end

    it 'fails if not ipv4 format' do
      expect{Address.new('name', 'FQDN', '1.2')}.to raise_error(ArgumentError)
    end

    it 'succeeds when valid' do
      address = Address.new('name', 'FQDN', '1.1.1.1')
      expect(address).to be_a Address
    end
  end
end
