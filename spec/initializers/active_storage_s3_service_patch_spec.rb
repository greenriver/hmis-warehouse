###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'

RSpec.describe 'ActiveStorage S3Service monkey patch' do
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_resource) { instance_double(Aws::S3::Resource) }
  let(:bucket) { instance_double(Aws::S3::Bucket, name: 'test-bucket') }
  let(:transfer_manager) { instance_double(Aws::S3::TransferManager) }
  let(:s3_service) { @s3_service }

  before do
    # Mock AWS SDK components BEFORE creating S3Service
    allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
    allow(s3_resource).to receive(:bucket).and_return(bucket)
    allow(Aws::S3::TransferManager).to receive(:new).and_return(transfer_manager)
    # Ensure bucket responds to name
    allow(bucket).to receive(:name).and_return('test-bucket')
    # Mock the client chain: Resource.client returns Client
    allow(s3_resource).to receive(:client).and_return(s3_client)
    @s3_service = ActiveStorage::Service::S3Service.new(
      bucket: 'test-bucket',
      access_key_id: 'test_key',
      secret_access_key: 'test_secret',
      region: 'us-east-1',
    )
    # Override client to return our mocked resource
    allow(@s3_service).to receive(:client).and_return(s3_resource)
  end

  describe 'upload_with_multipart' do
    # Create a large file that will trigger multipart upload (> 100MB threshold)
    # Use a simple mock IO object instead of trying to mock StringIO methods
    let(:large_io) do
      # Create a simple IO-like object that responds to size and read
      # IO.copy_stream calls read with (length, buffer) or (length), so we need to accept variable args
      io = Object.new
      def io.size
        150 * 1024 * 1024 # 150MB
      end

      def io.read(*_args)
        'x' * 1024 # Return small chunk
      end

      io
    end

    it 'uses TransferManager instead of deprecated upload_stream' do
      expect(transfer_manager).to receive(:upload_stream) do |options, &block|
        expect(options[:bucket]).to eq('test-bucket')
        expect(options[:key]).to eq('test-key')
        expect(options[:part_size]).to be_present
        # Call the block to simulate the upload
        write_stream = StringIO.new
        block&.call(write_stream)
      end

      # This should not raise and should use TransferManager
      expect do
        s3_service.send(:upload_with_multipart, 'test-key', large_io)
      end.not_to raise_error
    end

    it 'does not emit deprecation warning' do
      allow(transfer_manager).to receive(:upload_stream).and_yield(StringIO.new)

      expect do
        s3_service.send(:upload_with_multipart, 'test-key', large_io)
      end.to_not output(/DEPRECATION WARNING.*upload_stream/).to_stderr
    end

    it 'passes correct parameters to TransferManager' do
      expect(transfer_manager).to receive(:upload_stream) do |options|
        expect(options[:bucket]).to eq('test-bucket')
        expect(options[:key]).to eq('test-key')
        expect(options[:part_size]).to be >= 5.megabytes
        expect(options[:content_type]).to be_nil
      end.and_yield(StringIO.new)

      s3_service.send(:upload_with_multipart, 'test-key', large_io, content_type: nil)
    end
  end

  describe 'compose' do
    let(:source_keys) { ['source1', 'source2'] }
    let(:destination_key) { 'destination' }

    before do
      # Mock the stream method used by compose
      allow(s3_service).to receive(:stream).and_yield('chunk1').and_yield('chunk2')
    end

    it 'uses TransferManager instead of deprecated upload_stream' do
      expect(transfer_manager).to receive(:upload_stream) do |options, &block|
        expect(options[:bucket]).to eq('test-bucket')
        expect(options[:key]).to eq(destination_key)
        # Call the block to simulate the upload
        write_stream = StringIO.new
        block&.call(write_stream)
      end

      s3_service.compose(source_keys, destination_key)
    end

    it 'does not emit deprecation warning' do
      allow(transfer_manager).to receive(:upload_stream).and_yield(StringIO.new)

      expect do
        s3_service.compose(source_keys, destination_key)
      end.to_not output(/DEPRECATION WARNING.*upload_stream/).to_stderr
    end
  end
end
