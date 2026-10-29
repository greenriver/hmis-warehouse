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

    context 'when the bucket does not exist' do
      before do
        stub_const('ENV', ENV.to_h.merge('S3_PUBLIC_BUCKET' => 'pub-bucket'))
        client.stub_responses(:head_bucket, 'NotFound')
      end

      def created_buckets
        client.api_requests.select { |r| r[:operation_name] == :create_bucket }.map { |r| r[:params][:bucket] }
      end

      it 'creates it on the local S3 endpoint' do
        allow(AwsS3).to receive(:local_endpoint?).and_return(true)
        client.stub_responses(:create_bucket, { location: '/pub-bucket' })

        expect([publisher.ready_public_s3_bucket!, created_buckets]).to eq([true, ['pub-bucket']])
      end

      it 'fails when S3 reports the bucket at another location' do
        allow(AwsS3).to receive(:local_endpoint?).and_return(true)
        client.stub_responses(:create_bucket, { location: '/other-bucket' })

        expect(publisher.ready_public_s3_bucket!).to be(false)
      end

      it 'creates it and then adds the website config on AWS' do
        allow(AwsS3).to receive(:local_endpoint?).and_return(false)
        client.stub_responses(:head_bucket, ['NotFound', {}])
        client.stub_responses(:create_bucket, { location: '/pub-bucket' })
        client.stub_responses(:get_bucket_website, ['NoSuchWebsiteConfiguration', { index_document: { suffix: 'index.html' } }])
        client.stub_responses(:put_bucket_website, {})

        result = publisher.ready_public_s3_bucket!
        operations = client.api_requests.map { |r| r[:operation_name] }

        expect([result, created_buckets]).to eq([true, ['pub-bucket']])
        expect(operations.index(:create_bucket)).to be < operations.index(:put_bucket_website)
      end
    end
  end

  describe 'publishing a single-file report' do
    # PointInTime does not override push_to_s3/remove_from_s3, so it exercises the concern's versions.
    let(:report) do
      r = PublicReports::PointInTime.new(user: create(:acl_user), filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } }, version_slug: 'v1')
      r.save!(validate: false)
      r.update_columns(precalculated_data: [['x', '2024-01-31'], ['People', 1432]].to_json, completed_at: Time.zone.parse('2026-01-05'))
      r
    end

    before do
      client.stub_responses(:put_object, { etag: '"etag"' })
      client.stub_responses(:delete_object, { delete_marker: true })
    end

    it 'uploads the rendered html as one public-read object at the publish url' do
      report.publish!

      put = client.api_requests.find { |r| r[:operation_name] == :put_object }[:params]
      expect(put.values_at(:bucket, :key, :acl, :content_type)).to eq(['test', URI(report.generate_publish_url).path.delete_prefix('/'), 'public-read', 'text/html'])
      expect(put[:key]).to eq('point-in-time/v1/index.html')
      expect(put[:body]).to eq(report.reload.html)
      expect(put[:body]).to include(%(columns: [["x","2024-01-31"],["People",1432]]))
    end

    it 'deletes that object on unpublish' do
      report.update_columns(published_url: report.generate_publish_url, html: '<html></html>', state: 'published')

      report.unpublish!

      expect(client.api_requests.map { |r| [r[:operation_name], r[:params][:key]] }).to eq([[:delete_object, 'point-in-time/v1/index.html']])
      expect(report.reload.published_url).to be_nil
    end
  end
end
