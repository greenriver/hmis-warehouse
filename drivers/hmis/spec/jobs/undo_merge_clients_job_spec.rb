###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::UndoMergeClientsJob, type: :job do
  let(:data_source) { create(:hmis_data_source) }
  let(:actor) { create(:user) }
  let(:retained_client) { create(:hmis_hud_client_complete, date_created: Time.current - 1.week, data_source: data_source) }
  let(:deleted_client) { create(:hmis_hud_client_complete, date_created: Time.current - 5.days, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let!(:deleted_client_enrollment) { create(:hmis_hud_enrollment, client: deleted_client, project: project, data_source: data_source) }
  let!(:deleted_client_name) { create(:hmis_hud_custom_client_name, client: deleted_client, data_source: data_source) }
  let!(:deleted_client_file) { create(:client_file, client_id: deleted_client.id) }

  before do
    # Perform a merge
    Hmis::MergeClientsJob.perform_now(
      client_ids: [retained_client.id, deleted_client.id],
      actor_id: actor.id,
    )
    deleted_client.reload
  end

  describe '#perform' do
    it 'raises error if clients were not merged' do
      other_client = create(:hmis_hud_client_complete, data_source: data_source)
      expect do
        described_class.perform_now(
          retained_client_id: retained_client.id,
          deleted_client_id: other_client.id,
        )
      end.to raise_error(ArgumentError, 'Clients have not been merged')
    end

    it 'raises error if deleted client is not soft-deleted' do
      # Restore the deleted client first
      deleted_client.restore
      expect do
        described_class.perform_now(
          retained_client_id: retained_client.id,
          deleted_client_id: deleted_client.id,
        )
      end.to raise_error(ArgumentError, 'Deleted client is not soft-deleted')
    end

    it 'restores the deleted client' do
      expect(deleted_client.deleted?).to be true

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client.reload
      expect(deleted_client.deleted?).to be false
    end

    it 'restores client attributes from pre-merge state' do
      original_attributes = deleted_client.attributes.except('id', 'created_at', 'updated_at', 'deleted_at')

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client.reload
      # Check a few key attributes
      expect(deleted_client.personal_id).to eq(original_attributes['personal_id'])
    end

    it 'transfers enrollments back to deleted client' do
      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client_enrollment.reload
      expect(deleted_client_enrollment.personal_id).to eq(deleted_client.personal_id)
      expect(deleted_client_enrollment.client).to eq(deleted_client)
    end

    it 'restores names to deleted client' do
      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client_name.reload
      expect(deleted_client_name.PersonalID).to eq(deleted_client.personal_id)
    end

    it 'restores files to deleted client' do
      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client_file.reload
      expect(deleted_client_file.client_id).to eq(deleted_client.id)
    end
  end
end

