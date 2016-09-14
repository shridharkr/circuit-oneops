require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/status_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Status Request' do
  context 'initialize' do
    it 'fails when key is nil' do
      expect{StatusRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{StatusRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      key = Key.new('value')
      address_req = StatusRequest.new('url', key)
      expect(address_req).to be_a StatusRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{StatusRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'get status' do
    it 'returns a valid status object'

    it 'throws an exception when there was an error from the firewall'

  end

  context 'job complete' do
    it 'returns a false when the job is not complete'

    it 'returns a true when the job is complete'

    it 'throws an exception if the job is completed, but has a bad return code'

  end
end
