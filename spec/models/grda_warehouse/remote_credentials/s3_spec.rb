# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::RemoteCredentials::S3 do
  describe 'attribute assignment' do
    it 'assigns s3_secret_access_key correctly' do
      s3 = described_class.new(
        bucket: 'foobar1',
        region: 'us-east-1',
        s3_access_key_id: '12311212',
        s3_secret_access_key: '1212111',
      )
      expect(s3.s3_secret_access_key).to eq('1212111')
    end
  end
end
