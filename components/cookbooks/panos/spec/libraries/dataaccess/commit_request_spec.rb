require 'spec_helper'

require File.expand_path('../../../../libraries/dataaccess/commit_request.rb', __FILE__)
require File.expand_path('../../../../libraries/models/key.rb', __FILE__)

describe 'Commit Request' do
  context 'initialize' do
    it 'fails when key is nil' do
      expect{CommitRequest.new('url', nil)}.to raise_error(ArgumentError)
    end

    it 'fails when key is not of type Key' do
      expect{CommitRequest.new('url', 'userid')}.to raise_error(ArgumentError)
    end

    it 'succeeds when key is of type Key' do
      key = Key.new('value')
      address_req = CommitRequest.new('url', key)
      expect(address_req).to be_a CommitRequest
    end

    it 'fails when url is nil' do
      key = Key.new('value')
      expect{CommitRequest.new(nil, key)}.to raise_error(ArgumentError)
    end
  end

  context 'commit configs' do
    it 'returns a valid panos_job object'

    it 'throws an exception when there was an error from the firewall'

  end
end
