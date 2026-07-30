###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::DashboardExportFile, type: :model do
  let(:bytes) { 'zipbytes' * 50 }

  def build_file
    described_class.new(file: 'export.zip', content_type: 'application/zip', content: bytes)
  end

  it 'exposes file_data with attachment fallback' do
    file = build_file
    expect(file.file_data).to eq(bytes)
    file.save!(validate: false)
    file.content = nil
    file.dashboard_export_file.attach(io: StringIO.new(bytes), filename: 'export.zip', content_type: 'application/zip')
    file.save!(validate: false)
    expect(file.file_data).to eq(bytes)
  end

  it 'migrates content to S3 and nulls it' do
    file = build_file
    file.save!(validate: false)
    file.copy_to_s3!
    file.reload
    expect(file.dashboard_export_file).to be_attached
    expect(file.content).to be_nil
  end

  it 'scopes only unmigrated rows of its own STI type' do
    migrated = build_file
    migrated.save!(validate: false)
    migrated.dashboard_export_file.attach(io: StringIO.new(bytes), filename: 'export.zip', content_type: 'application/zip')
    pending_row = build_file
    pending_row.save!(validate: false)
    ids = described_class.unprocessed_s3_migration.pluck(:id)
    expect(ids).to eq([pending_row.id])
  end
end
