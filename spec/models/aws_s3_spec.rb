###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'
require 'securerandom'

# quick smoke tests for aws s3 client wrapper
RSpec.describe AwsS3 do
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:s3_resource) { instance_double(Aws::S3::Resource) }
  let(:bucket) { instance_double(Aws::S3::Bucket) }
  let(:object) { instance_double(Aws::S3::Object) }
  let(:aws_s3) { AwsS3.new(bucket_name: 'test-bucket') }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
    allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
    allow(s3_resource).to receive(:bucket).and_return(bucket)
    allow(bucket).to receive(:object).and_return(object)
  end

  describe 'region' do
    def region_for(env)
      stub_const('ENV', ENV.to_h.except('AWS_REGION', 'AWS_DEFAULT_REGION').merge(env))
      AwsS3.new(bucket_name: 'test-bucket')
      region = nil
      expect(Aws::S3::Client).to have_received(:new) { |options| region = options[:region] }
      region
    end

    it 'uses AWS_REGION over AWS_DEFAULT_REGION' do
      expect(region_for('AWS_REGION' => 'us-east-2', 'AWS_DEFAULT_REGION' => 'us-west-2')).to eq('us-east-2')
    end

    it 'uses AWS_DEFAULT_REGION when AWS_REGION is blank' do
      expect(region_for('AWS_REGION' => '', 'AWS_DEFAULT_REGION' => 'us-west-2')).to eq('us-west-2')
    end

    it 'falls back to us-east-1 when neither is set' do
      expect(region_for({})).to eq('us-east-1')
    end
  end

  describe '.local_endpoint?' do
    def local_endpoint_with(env)
      stub_const('ENV', ENV.to_h.except('USE_LOCAL_S3_ENDPOINT', 'LOCAL_S3_ENDPOINT').merge(env))
      AwsS3.local_endpoint?
    end

    it 'is true only when the flag is "true" and an endpoint is set' do
      expect(
        [
          local_endpoint_with('USE_LOCAL_S3_ENDPOINT' => 'true', 'LOCAL_S3_ENDPOINT' => 'http://minio:9000'),
          local_endpoint_with('USE_LOCAL_S3_ENDPOINT' => 'true', 'LOCAL_S3_ENDPOINT' => ''),
          local_endpoint_with('USE_LOCAL_S3_ENDPOINT' => 'false', 'LOCAL_S3_ENDPOINT' => 'http://minio:9000'),
        ],
      ).to eq([true, false, false])
    end
  end

  describe '#exists?' do
    it 'returns what the bucket check reports' do
      allow(bucket).to receive(:exists?).and_return(true, false)

      expect([aws_s3.exists?, aws_s3.exists?]).to eq([true, false])
    end

    it 'returns false when the bucket check raises' do
      allow(bucket).to receive(:exists?).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'Forbidden'))

      expect(aws_s3.exists?).to be(false)
    end
  end

  describe '#put' do
    let(:prefix) { 'folder' }

    it 'uploads a file to s3 with correct bucket/key via TransferManager' do
      tm = instance_double(Aws::S3::TransferManager)
      resp = instance_double('UploadResponse', wait: true)
      allow(Aws::S3::TransferManager).to receive(:new).and_return(tm)

      Tempfile.open(['spec-upload', '.txt']) do |tf|
        tf.write('data')
        tf.flush

        expect(tm).to receive(:upload_file) do |path, opts|
          expect(path).to eq(tf.path)
          expect(opts).to include(bucket: 'test-bucket')
          expect(opts[:key]).to eq("#{prefix}/#{File.basename(tf.path)}")
        end.and_return(resp)

        aws_s3.put(file_name: tf.path, prefix: prefix)
      end
    end
  end

  describe '#store' do
    let(:content) { 'test' }
    let(:name) { 'file.txt' }

    it 'stores content in the s3 bucket' do
      expect(object).to receive(:put).with(body: content)
      aws_s3.store(content: content, name: name)
      expect(bucket).to have_received(:object).with(name)
    end
  end

  describe '#delete' do
    let(:key) { 'file_to_delete.txt' }

    it 'deletes the specified object from the bucket' do
      expect(s3_client).to receive(:delete_object).with(bucket: 'test-bucket', key: key)
      aws_s3.delete(key: key)
    end
  end

  describe '#list' do
    let(:prefix) { 'folder/' }
    let(:s3_object) { instance_double(Aws::S3::Object, key: "#{prefix}/file.txt", etag: '12345') }
    let(:object_collection) { [s3_object] }

    it 'lists objects in the bucket with the specified prefix' do
      allow(bucket).to receive(:objects).with(prefix: prefix).and_return(object_collection)
      expect(aws_s3.list(prefix: prefix)).to contain_exactly(s3_object)
      expect(bucket).to have_received(:objects).with(prefix: prefix)
    end
  end

  describe '#fetch' do
    let(:file_name) { 'test_file.txt' }
    let(:prefix) { 'folder' }
    let(:target_path) { 'local_path/test_file.txt' }
    let(:file_path) { "#{prefix}/#{file_name}" }

    it 'fetches the file from s3 and saves it to the specified path' do
      expect(object).to receive(:get).with(response_target: target_path)
      aws_s3.fetch(file_name: file_name, prefix: prefix, target_path: target_path)
      expect(bucket).to have_received(:object).with(file_path)
    end
  end

  describe '#upload_directory' do
    let(:directory_name) { 'path/to/files' }
    let(:prefix) { 'uploads' }
    let(:file_path) { "#{directory_name}/file1.txt" }
    let(:s3_key) { "#{prefix}/file1.txt" }

    before do
      allow(Dir).to receive(:exist?).with(directory_name).and_return(true)
      allow(Dir).to receive(:glob).with("#{directory_name}/*").and_return([file_path])
      allow(File).to receive(:directory?).with(file_path).and_return(false)
    end

    it 'uploads all files from the directory to the specified s3 bucket' do
      tm = instance_double(Aws::S3::TransferManager)
      resp = instance_double('UploadResponse', wait: true)
      allow(Aws::S3::TransferManager).to receive(:new).and_return(tm)

      expect(tm).to receive(:upload_file).with(file_path, hash_including(bucket: 'test-bucket', key: s3_key)).and_return(resp)

      aws_s3.upload_directory(directory_name: directory_name, prefix: prefix)
    end
  end
end

RSpec.describe AwsS3, 'deprecation warnings' do
  describe '#put' do
    let(:temp_file) { Tempfile.new(['test', '.txt']) }
    let(:prefix) { 'folder' }

    before do
      temp_file.write('test content')
      temp_file.rewind
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'triggers deprecation warning when calling upload_file' do
      # Build a real client but force the uploader to no-op so it doesn't sign
      allow_any_instance_of(Aws::S3::FileUploader).to receive(:upload).and_return(true)

      real_aws_s3 = AwsS3.new(
        bucket_name: 'test-bucket',
        access_key_id: 'test_key',
        secret_access_key: 'test_secret',
      )

      expect do
        real_aws_s3.put(file_name: temp_file.path, prefix: prefix)
      end.to_not output(/DEPRECATION WARNING/).to_stderr
    end
  end
end

RSpec.describe AwsS3, 'local S3 roundtrip' do
  it 'uploads then downloads the file and matches contents' do
    # Allow real HTTP to local S3 inside the docker network for this example
    begin
      WebMock.allow_net_connect!
    rescue NameError
      # webmock not loaded
    end

    previous_use_local_s3 = ENV['USE_LOCAL_S3_ENDPOINT']
    previous_local_s3_endpoint = ENV['LOCAL_S3_ENDPOINT']
    previous_ssl_verify = Aws.config[:ssl_verify_peer]
    prev_env_access = ENV['AWS_ACCESS_KEY_ID']
    prev_env_secret = ENV['AWS_SECRET_ACCESS_KEY']
    prev_env_region = ENV['AWS_REGION']

    ENV['USE_LOCAL_S3_ENDPOINT'] = 'true'
    endpoint = ENV['LOCAL_S3_ENDPOINT'].presence || 'https://s3.dev.test:9000'
    ENV['LOCAL_S3_ENDPOINT'] = endpoint
    Aws.config[:ssl_verify_peer] = false
    access_key_id = ENV['AWS_ACCESS_KEY_ID'].presence || 'local_access_key'
    secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'].presence || 'local_secret_key'

    bucket_name = ENV['S3_TMP_BUCKET'].presence || 'test'
    region = ENV['S3_TMP_REGION'].presence || 'us-east-1'

    begin
      s3 = AwsS3.new(
        bucket_name: bucket_name,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        region: region,
      )

      tf = Tempfile.new(['roundtrip', '.txt'])
      content = "hello-#{SecureRandom.hex(8)}"
      tf.write(content)
      tf.flush

      prefix = "rt-#{SecureRandom.hex(4)}"
      s3.put(file_name: tf.path, prefix: prefix)

      download = Tempfile.new(['roundtrip-download', '.txt'])
      download_path = download.path
      download.close!

      s3.fetch(file_name: File.basename(tf.path), prefix: prefix, target_path: download_path)

      expect(File.read(download_path)).to eq(content)
    ensure
      ENV['USE_LOCAL_S3_ENDPOINT'] = previous_use_local_s3
      ENV['LOCAL_S3_ENDPOINT'] = previous_local_s3_endpoint
      Aws.config[:ssl_verify_peer] = previous_ssl_verify
      ENV['AWS_ACCESS_KEY_ID'] = prev_env_access
      ENV['AWS_SECRET_ACCESS_KEY'] = prev_env_secret
      ENV['AWS_REGION'] = prev_env_region
      begin
        WebMock.disable_net_connect!
      rescue NameError
        # webmock not loaded
      end
    end
  end
end
