###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ReportResultFile, type: :model do
  let(:bytes) { 'reportzip' * 30 }

  def build_file
    described_class.new(file: 'result.zip', content_type: 'application/zip', content: bytes)
  end

  it 'exposes file_data with attachment fallback' do
    file = build_file
    expect(file.file_data).to eq(bytes)
    file.content = nil
    file.save!(validate: false)
    file.report_result_file.attach(io: StringIO.new(bytes), filename: 'result.zip', content_type: 'application/zip')
    expect(file.file_data).to eq(bytes)
  end

  it 'migrates content to S3 and nulls it' do
    file = build_file
    file.save!(validate: false)
    file.copy_to_s3!
    file.reload
    expect(file.report_result_file).to be_attached
    expect(file.content).to be_nil
  end

  it 'unprocessed_s3_migration excludes attached records and includes pending ones' do
    # Create a file with content (not yet migrated)
    pending_file = build_file
    pending_file.save!(validate: false)

    # Create another file, migrate it, then verify it's excluded
    migrated_file = build_file
    migrated_file.save!(validate: false)
    migrated_file.copy_to_s3!

    # Query unprocessed migration
    unprocessed = described_class.unprocessed_s3_migration.pluck(:id)

    # Should include pending, exclude migrated
    expect(unprocessed).to include(pending_file.id)
    expect(unprocessed).not_to include(migrated_file.id)
  end
end
