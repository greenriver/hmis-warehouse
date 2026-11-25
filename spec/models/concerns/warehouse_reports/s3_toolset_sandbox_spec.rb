###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::S3Toolset do
  let(:toolset_class) do
    Class.new do
      include WarehouseReports::S3Toolset

      def client
        s3_client
      end
    end
  end
  let(:toolset) { toolset_class.new }
  let(:aws_s3) { instance_double(AwsS3, client: instance_double(Aws::S3::Client, head_bucket: nil)) }

  before do
    allow(AwsS3).to receive(:new).and_return(aws_s3)
    allow(AwsS3).to receive(:local_endpoint?).and_return(true)
  end

  it 'builds an S3 client outside sandbox mode' do
    expect(toolset.client).to eq(aws_s3.client)
  end

  it 'refuses to build an S3 client in sandbox mode' do
    with_sandbox_mode do
      expect { toolset.client }.to raise_error(SandboxMode::IntegrationDisabled, 'Public report publishing is disabled in sandbox mode')
    end
    expect(AwsS3).not_to have_received(:new)
  end

  describe '#ready_public_s3_bucket!' do
    it 'is true when the bucket exists' do
      expect(toolset.ready_public_s3_bucket!).to be(true)
    end

    it 'is false in sandbox mode without contacting S3' do
      with_sandbox_mode do
        expect(toolset.ready_public_s3_bucket!).to be(false)
      end
      expect(AwsS3).not_to have_received(:new)
    end
  end
end
