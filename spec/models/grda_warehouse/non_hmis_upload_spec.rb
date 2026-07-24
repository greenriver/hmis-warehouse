###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::NonHmisUpload, type: :model do
  let(:data_source) { create :grda_warehouse_data_source }
  let(:bytes) { 'col_a,col_b\n1,2\n' }

  def build_upload
    # NOTE: `mount_uploader :file` intercepts a plain string assigned to `file=`
    # (it's treated as a CarrierWave cache identifier, not a literal value), so
    # assigning `file: 'test.csv'` via .new leaves the NOT NULL `file` column
    # nil. Write the raw attribute directly to bypass CarrierWave's setter.
    described_class.new(
      data_source: data_source,
      content_type: 'text/csv',
      content: bytes,
    ).tap { |upload| upload.write_attribute(:file, 'test.csv') }
  end

  describe '#file_data' do
    it 'returns the content column when not attached' do
      upload = build_upload
      expect(upload.file_data).to eq(bytes)
    end

    it 'returns the attachment bytes when attached' do
      upload = build_upload
      upload.content = nil
      upload.save!(validate: false)
      upload.upload_file.attach(io: StringIO.new(bytes), filename: 'test.csv', content_type: 'text/csv')
      expect(upload.file_data).to eq(bytes)
    end
  end

  describe '#copy_to_s3!' do
    it 'attaches content to S3 and nulls the content column' do
      upload = build_upload
      upload.save!(validate: false)
      upload.copy_to_s3!
      upload.reload
      expect(upload.upload_file).to be_attached
      expect(upload.upload_file.download).to eq(bytes)
      expect(upload.content).to be_nil
    end

    it 'is a no-op when already attached' do
      upload = build_upload
      upload.save!(validate: false)
      upload.upload_file.attach(io: StringIO.new(bytes), filename: 'test.csv', content_type: 'text/csv')
      expect { upload.copy_to_s3! }.not_to(change { ActiveStorage::Attachment.count })
    end
  end

  describe 'create validation' do
    # Mirrors the controller create flow: new uploads store bytes in ActiveStorage
    # (`upload_file`), not through the CarrierWave `:file` mount, so create-time
    # presence must be satisfied by the attachment.
    it 'is valid on create when the file is attached to ActiveStorage' do
      # Presence must come from the ActiveStorage attachment, NOT the legacy
      # CarrierWave `:file` column — so deliberately do not write that column.
      upload = described_class.new(data_source: data_source, content_type: 'text/csv')
      upload.upload_file.attach(io: StringIO.new(bytes), filename: 'test.csv', content_type: 'text/csv')
      expect(upload).to be_valid
    end

    it 'is invalid on create when no file is attached' do
      upload = described_class.new(data_source: data_source)
      expect(upload).not_to be_valid
      expect(upload.errors[:file]).to be_present
    end
  end

  describe '.unprocessed_s3_migration' do
    it 'excludes rows already attached' do
      migrated = build_upload
      migrated.save!(validate: false)
      migrated.upload_file.attach(io: StringIO.new(bytes), filename: 'test.csv', content_type: 'text/csv')
      pending_row = build_upload
      pending_row.save!(validate: false)

      ids = described_class.unprocessed_s3_migration.pluck(:id)
      expect(ids).to include(pending_row.id)
      expect(ids).not_to include(migrated.id)
    end
  end
end
