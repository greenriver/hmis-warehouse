###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'grda_warehouse:ftps_s3_sync', type: :task do
  let(:task_name) { 'grda_warehouse:ftps_s3_sync' }

  let!(:sync) do
    GrdaWarehouse::LftpS3Sync.create!(
      data_source: create(:grda_warehouse_data_source),
      ftp_host: 'ftp.example.org',
      ftp_user: 'user',
      ftp_pass: 'pass',
      ftp_path: '/',
    )
  end

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'grda_warehouse:ftps_s3_sync' }
  end

  before do
    allow_any_instance_of(GrdaWarehouse::LftpS3Sync).to receive(:fetch_and_push)
    Rake::Task[task_name].reenable
  end

  it 'syncs each configured source outside sandbox mode' do
    expect_any_instance_of(GrdaWarehouse::LftpS3Sync).to receive(:fetch_and_push).once

    Rake::Task[task_name].invoke
  end

  it 'syncs nothing in sandbox mode' do
    expect_any_instance_of(GrdaWarehouse::LftpS3Sync).not_to receive(:fetch_and_push)

    with_sandbox_mode { Rake::Task[task_name].invoke }
  end
end
