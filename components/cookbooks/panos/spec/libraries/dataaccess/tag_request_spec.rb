require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/tag_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Tag Request' do
  context 'initialize' do
    it 'fails when key is nil' do
      expect{AddressRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{AddressRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      key = Key.new('value')
      address_req = AddressRequest.new('url', key)
      expect(address_req).to be_a AddressRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{AddressRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'create tag' do
    it 'succeeds when it creates the tag'
    
    it 'throws an exception when there was an error from the firewall'
    
  end
  
end
