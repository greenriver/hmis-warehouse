# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeUnattachedBlobsJob, type: :job do
  describe '#perform' do
    let!(:old_unattached_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('old test content'),
        filename: 'old_test.pdf',
        content_type: 'application/pdf',
      ).tap { |blob| blob.update_column(:created_at, 3.days.ago) }
    end

    let!(:recent_unattached_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('recent test content'),
        filename: 'recent_test.pdf',
        content_type: 'application/pdf',
      )
    end

    let!(:old_attached_blob) do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('attached content'),
        filename: 'attached_test.pdf',
        content_type: 'application/pdf',
      )
      blob.update_column(:created_at, 3.days.ago)

      # Attach to a test record to make it "attached"
      ActiveStorage::Attachment.create!(
        name: 'test_attachment',
        record_type: 'User',
        record_id: create(:user).id,
        blob: blob,
      )

      blob
    end

    it 'purges old unattached blobs' do
      expect { described_class.new.perform }.
        to change { ActiveStorage::Blob.exists?(old_unattached_blob.id) }.from(true).to(false)
    end

    it 'preserves recent unattached blobs' do
      expect { described_class.new.perform }.
        not_to(change { ActiveStorage::Blob.exists?(recent_unattached_blob.id) })
    end

    it 'preserves old attached blobs' do
      expect { described_class.new.perform }.
        not_to(change { ActiveStorage::Blob.exists?(old_attached_blob.id) })
    end

    it 'respects custom older_than parameter' do
      described_class.new.perform(older_than: 4.days)

      expect(ActiveStorage::Blob.exists?(old_unattached_blob.id)).to be true
      expect(ActiveStorage::Blob.exists?(recent_unattached_blob.id)).to be true
    end
  end
end
