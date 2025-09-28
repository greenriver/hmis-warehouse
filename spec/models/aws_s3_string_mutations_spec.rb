# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwsS3, type: :model do
  let(:bucket_name) { 'test-bucket' }
  let(:region) { 'us-east-1' }
  let(:access_key_id) { 'test_key' }
  let(:secret_access_key) { 'test_secret' }

  before do
    # Mock AWS SDK to avoid actual API calls
    mock_bucket = double('bucket')
    mock_resource = double('resource')
    allow(mock_resource).to receive(:bucket).with(bucket_name).and_return(mock_bucket)
    allow(Aws::S3::Client).to receive(:new).and_return(double('client'))
    allow(Aws::S3::Resource).to receive(:new).and_return(mock_resource)
  end

  describe 'string mutation operations' do
    subject(:aws_s3) { described_class.new(bucket_name: bucket_name, access_key_id: access_key_id, secret_access_key: secret_access_key) }

    before do
      # Mock bucket and client for testing
      mock_bucket = double('bucket')
      mock_client = double('client')
      allow(aws_s3).to receive(:bucket).and_return(mock_bucket)
      allow(aws_s3).to receive(:client).and_return(mock_client)
    end

    describe '#list_objects with += operations' do
      let(:mock_contents_batch_1) do
        [
          double('object1', key: 'file1.txt', last_modified: Time.current - 2.hours),
          double('object2', key: 'file2.txt', last_modified: Time.current - 1.hour),
        ]
      end
      let(:mock_contents_batch_2) do
        [
          double('object3', key: 'file3.txt', last_modified: Time.current - 3.hours),
          double('object4', key: 'file4.txt', last_modified: Time.current - 30.minutes),
        ]
      end

      it 'concatenates object arrays using += operators' do
        # Test the string mutations from lines 130 and 141:
        # objects += batch.contents (first batch)
        # objects += batch.contents (subsequent batches)

        # Mock the list_objects_v2 responses
        first_batch = double('first_batch', is_truncated: true, contents: mock_contents_batch_1)
        first_batch.contents.stub(:last).and_return(mock_contents_batch_1.last)

        second_batch = double('second_batch', is_truncated: false, contents: mock_contents_batch_2)

        allow(aws_s3.client).to receive(:list_objects_v2).and_return(first_batch, second_batch)

        objects = aws_s3.list_objects(1000, prefix: 'test/')

        # Verify that the += operations worked correctly
        expect(objects.length).to eq(4)
        expect(objects.map(&:key)).to include('file1.txt', 'file2.txt', 'file3.txt', 'file4.txt')
        # Should be sorted by last_modified and reversed (newest first, then limited)
        expect(objects.first.key).to eq('file4.txt') # Most recent
      end

      it 'handles single batch without truncation' do
        # Test the initial += operation when there's only one batch
        single_batch = double('single_batch', is_truncated: false, contents: mock_contents_batch_1)

        allow(aws_s3.client).to receive(:list_objects_v2).and_return(single_batch)

        objects = aws_s3.list_objects(1000, prefix: 'test/')

        expect(objects.length).to eq(2)
        expect(objects.map(&:key)).to include('file1.txt', 'file2.txt')
      end

      it 'respects max_keys limit after concatenation' do
        # Test that the concatenation works correctly and respects the max_keys limit
        first_batch = double('first_batch', is_truncated: true, contents: mock_contents_batch_1)
        first_batch.contents.stub(:last).and_return(mock_contents_batch_1.last)

        second_batch = double('second_batch', is_truncated: false, contents: mock_contents_batch_2)

        allow(aws_s3.client).to receive(:list_objects_v2).and_return(first_batch, second_batch)

        objects = aws_s3.list_objects(2, prefix: 'test/')

        # Should concatenate all, then limit to max_keys
        expect(objects.length).to eq(2)
      end

      it 'handles empty batches correctly' do
        empty_batch = double('empty_batch', is_truncated: false, contents: [])

        allow(aws_s3.client).to receive(:list_objects_v2).and_return(empty_batch)

        objects = aws_s3.list_objects(1000, prefix: 'test/')

        expect(objects).to eq([])
      end

      it 'continues concatenating through multiple truncated batches' do
        # Test multiple += operations across several batches
        batch_1 = double('batch_1', is_truncated: true, contents: [mock_contents_batch_1[0]])
        batch_1.contents.stub(:last).and_return(mock_contents_batch_1[0])

        batch_2 = double('batch_2', is_truncated: true, contents: [mock_contents_batch_1[1]])
        batch_2.contents.stub(:last).and_return(mock_contents_batch_1[1])

        batch_3 = double('batch_3', is_truncated: false, contents: mock_contents_batch_2)

        allow(aws_s3.client).to receive(:list_objects_v2).and_return(batch_1, batch_2, batch_3)

        objects = aws_s3.list_objects(1000, prefix: 'test/')

        expect(objects.length).to eq(4)
        expect(objects.map(&:key)).to include('file1.txt', 'file2.txt', 'file3.txt', 'file4.txt')
      end
    end
  end
end
