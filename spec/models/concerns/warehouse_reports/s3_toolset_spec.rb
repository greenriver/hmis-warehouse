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

    it 'needs the website config too on real S3' do
      allow(AwsS3).to receive(:local_endpoint?).and_return(false)

      expect(publisher.ready_public_s3_bucket!).to be(false)
    end

    it 'names the bucket from CLIENT when S3_PUBLIC_BUCKET is blank' do
      stub_const('ENV', ENV.to_h.merge('S3_PUBLIC_BUCKET' => '', 'CLIENT' => 'my_client'))
      allow(AwsS3).to receive(:local_endpoint?).and_return(true)

      publisher.ready_public_s3_bucket!

      expect(client.api_requests.first[:params][:bucket]).to eq('my-client-test-public')
    end
  end
end
