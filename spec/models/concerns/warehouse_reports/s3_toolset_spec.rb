###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::S3Toolset do
  let(:publisher) { Class.new { include WarehouseReports::S3Toolset }.new }
  # The bucket exists, it has no website config, and setting one up is refused.
  let(:client) do
    Aws::S3::Client.new(
      credentials: Aws::Credentials.new('key', 'secret'),
      region: 'us-east-1',
      stub_responses: {
        head_bucket: {},
        get_bucket_website: 'NoSuchWebsiteConfiguration',
        put_bucket_website: 'AccessDenied',
      },
    )
  end

  before do
    allow(AwsS3).to receive(:new).and_return(instance_double(AwsS3, client: client))
  end

  describe '#ready_public_s3_bucket!' do
    it 'needs only the bucket on the local S3 endpoint, which has no website API' do
      allow(AwsS3).to receive(:local_endpoint?).and_return(true)

      expect(publisher.ready_public_s3_bucket!).to be(true)
    end

    it 'adds the website config to an existing bucket that lacks one' do
      allow(AwsS3).to receive(:local_endpoint?).and_return(false)
      client.stub_responses(:get_bucket_website, ['NoSuchWebsiteConfiguration', { index_document: { suffix: 'index.html' } }])
      client.stub_responses(:put_bucket_website, {})

      expect(publisher.ready_public_s3_bucket!).to be(true)
      expect(client.api_requests.map { |r| r[:operation_name] }).to include(:put_bucket_website)
    end

    it 'fails when S3 refuses the website config' do
      allow(AwsS3).to receive(:local_endpoint?).and_return(false)

      expect(publisher.ready_public_s3_bucket!).to be(false)
      expect(client.api_requests.map { |r| r[:operation_name] }).to include(:put_bucket_website)
    end

    it 'builds the client from the public S3 credentials' do
      stub_const('ENV', ENV.to_h.merge('S3_PUBLIC_BUCKET' => 'pub-bucket', 'S3_PUBLIC_ACCESS_KEY_ID' => 'pub-key', 'S3_PUBLIC_ACCESS_KEY_SECRET' => 'pub-secret'))
      allow(AwsS3).to receive(:local_endpoint?).and_return(true)

      publisher.ready_public_s3_bucket!

      expect(AwsS3).to have_received(:new).with(bucket_name: 'pub-bucket', access_key_id: 'pub-key', secret_access_key: 'pub-secret')
    end

    it 'names the bucket from CLIENT when S3_PUBLIC_BUCKET is blank' do
      stub_const('ENV', ENV.to_h.merge('S3_PUBLIC_BUCKET' => '', 'CLIENT' => 'my_client'))
      allow(AwsS3).to receive(:local_endpoint?).and_return(true)

      publisher.ready_public_s3_bucket!

      expect(client.api_requests.first[:params][:bucket]).to eq('my-client-test-public')
    end
  end
end
