require 'rails_helper'
require 'aws-sdk-s3'

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

  describe '#initialize' do
    it 'initializes with given bucket name and region' do
      expect(aws_s3.bucket_name).to eq('test-bucket')
    end
  end

  describe '#exists?' do
    it 'returns true if bucket exists' do
      allow(bucket).to receive(:exists?).and_return(true)
      expect(aws_s3.exists?).to be true
    end
  end

  describe '#put' do
    let(:file_name) { 'test_file.txt' }
    let(:prefix) { 'folder' }
    let(:file_path) { "#{prefix}/#{file_name}" }

    it 'uploads a file to s3 with correct path' do
      allow(object).to receive(:upload_file).with(file_name)
      aws_s3.put(file_name: file_name, prefix: prefix)
      expect(bucket).to have_received(:object).with(file_path)
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
      expect(object).to receive(:upload_file).with(file_path)
      aws_s3.upload_directory(directory_name: directory_name, prefix: prefix)
      expect(bucket).to have_received(:object).with(s3_key)
    end
  end
end
