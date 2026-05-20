# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeSoftDeletedClientFilesJob, type: :job do
  let!(:file_old) { create(:client_file) }
  let!(:file_recent) { create(:client_file) }
  let!(:file_active) { create(:client_file) }

  before do
    file_old.update_columns(deleted_at: 60.days.ago)
    file_recent.update_columns(deleted_at: 10.days.ago)
  end

  describe '#perform' do
    it 'purges only files deleted before the retention window' do
      expect do
        described_class.new.perform(retain_at: 30.days.ago)
      end.to change { GrdaWarehouse::ClientFile.with_deleted.count }.by(-1)

      expect(GrdaWarehouse::ClientFile.with_deleted.exists?(file_old.id)).to be false
      expect(GrdaWarehouse::ClientFile.with_deleted.exists?(file_recent.id)).to be true
      expect(GrdaWarehouse::ClientFile.with_deleted.exists?(file_active.id)).to be true
    end

    it 'preserves active files' do
      described_class.new.perform(retain_at: 30.days.ago)

      expect(file_active.reload.deleted_at).to be_nil
    end

    it 'purges ActiveStorage attachments for deleted files' do
      blob_id = file_old.client_file.blob.id

      described_class.new.perform(retain_at: 30.days.ago)

      expect(ActiveStorage::Blob.exists?(blob_id)).to be false
    end
  end
end
