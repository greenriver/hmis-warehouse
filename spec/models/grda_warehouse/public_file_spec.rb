###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::PublicFile, type: :model do
  let(:bytes) { ('a'..'z').to_a.join * 20 } # > 100 bytes, < 4 MB

  def build_file
    described_class.new(name: 'client/releases/coc_map', content_type: 'image/png', content: bytes)
  end

  describe '#file_data' do
    it 'returns content when not attached, attachment when attached' do
      file = build_file
      expect(file.file_data).to eq(bytes)

      file.content = nil
      file.save!(validate: false)
      file.public_file.attach(io: StringIO.new(bytes), filename: 'coc_map.png', content_type: 'image/png')
      expect(file.file_data).to eq(bytes)
    end
  end

  describe '#copy_to_s3!' do
    it 'attaches and nulls content' do
      file = build_file
      file.save!(validate: false)
      file.copy_to_s3!
      file.reload
      expect(file.public_file).to be_attached
      expect(file.public_file.download).to eq(bytes)
      expect(file.content).to be_nil
    end
  end

  describe 'content type validation' do
    # CarrierWave's FileUploader#content_type_whitelist used to reject these on
    # upload; new uploads bypass CarrierWave entirely, so this restores the check
    # against the ActiveStorage attachment instead.
    it 'rejects disallowed content types on create' do
      file = described_class.new(name: 'test', content_type: 'application/x-msdownload')
      file.public_file.attach(io: StringIO.new(bytes), filename: 'x.exe', content_type: 'application/x-msdownload')
      expect(file).not_to be_valid
      expect(file.errors[:file]).to include('You are not allowed to upload application/x-msdownload files')
    end

    it 'accepts an allowed content type on create' do
      file = described_class.new(name: 'test', content_type: 'image/png')
      file.public_file.attach(io: StringIO.new(bytes), filename: 'x.png', content_type: 'image/png')
      expect(file).to be_valid
    end

    it 'does not block copy_to_s3! migration of legacy rows with disallowed content types' do
      file = described_class.new(name: 'legacy', content_type: 'application/x-msdownload', content: bytes)
      file.save!(validate: false)
      expect { file.copy_to_s3! }.not_to raise_error
      file.reload
      expect(file.public_file).to be_attached
    end
  end

  describe '.unprocessed_s3_migration' do
    it 'does not bleed across sibling STI types on the files table' do
      client = create :hud_client
      sibling = GrdaWarehouse::ClientFile.new(client: client, name: 'x', visible_in_window: false)
      sibling.client_file.attach(io: StringIO.new(bytes), filename: 'x.png', content_type: 'image/png')
      sibling.save!(validate: false)

      pending_row = build_file
      pending_row.save!(validate: false)

      ids = described_class.unprocessed_s3_migration.pluck(:id)
      expect(ids).to eq([pending_row.id])
    end

    it 'excludes already-migrated rows and includes pending rows' do
      migrated_row = build_file
      migrated_row.save!(validate: false)
      migrated_row.public_file.attach(io: StringIO.new(bytes), filename: 'coc_map.png', content_type: 'image/png')

      pending_row = build_file
      pending_row.save!(validate: false)

      ids = described_class.unprocessed_s3_migration.pluck(:id)
      expect(ids).to include(pending_row.id)
      expect(ids).not_to include(migrated_row.id)
    end
  end
end
