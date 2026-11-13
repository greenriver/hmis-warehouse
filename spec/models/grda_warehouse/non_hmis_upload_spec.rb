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
    described_class.new(
      data_source: data_source,
      content_type: 'text/csv',
      content: bytes,
      file: 'test.csv',
    )
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

  describe '#detected_content_type' do
    it 'prefers the byte-derived type over the claimed one' do
      upload = described_class.new(data_source: data_source, content_type: 'text/csv')
      upload.upload_file.attach(io: StringIO.new("%PDF-1.4\nnot a csv\n"), filename: 'x.csv', content_type: 'text/csv')
      expect(upload.detected_content_type).to eq('application/pdf')
    end

    it 'falls back to the column for un-migrated rows' do
      expect(build_upload.detected_content_type).to eq('text/csv')
    end
  end

  describe '#filename' do
    it 'returns the legacy column for un-migrated rows' do
      expect(build_upload.filename).to eq('test.csv')
    end

    it 'prefers the attachment name once migrated' do
      upload = build_upload
      upload.save!(validate: false)
      upload.upload_file.attach(io: StringIO.new(bytes), filename: 'renamed.xlsx', content_type: 'text/csv')
      expect(upload.filename).to eq('renamed.xlsx')
    end

    # Mirrors the controller create flow: the legacy `file` column is left null.
    it 'saves and reports the attachment name with the legacy column null' do
      upload = described_class.new(data_source: data_source, content_type: 'text/csv')
      upload.upload_file.attach(io: StringIO.new(bytes), filename: 'new_style.xlsx', content_type: 'text/csv')
      expect { upload.save! }.not_to raise_error
      upload.reload
      expect(upload[:file]).to be_nil
      expect(upload.filename).to eq('new_style.xlsx')
    end

    it 'returns an empty string when neither is present' do
      expect(described_class.new(data_source: data_source).filename).to eq('')
    end
  end

  describe 'create validation' do
    # Mirrors the controller create flow: new uploads store bytes in ActiveStorage
    # (`upload_file`), so create-time presence must be satisfied by the attachment.
    it 'is valid on create when the file is attached to ActiveStorage' do
      # Presence must come from the ActiveStorage attachment, NOT the legacy
      # `:file` column — so deliberately do not write that column.
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
end
