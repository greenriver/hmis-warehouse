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
  let!(:deleted_client_file) { create(:file, :skip_validate, client_id: deleted_client.id) }
  let!(:deleted_client_ce_referral) { create(:hmis_ce_referral, data_source: data_source, client: deleted_client) }

  describe '#perform' do
    before do
      Hmis::MergeClientsJob.perform_now(
        client_ids: [retained_client.id, deleted_client.id],
        actor_id: actor.id,
      )
      deleted_client.reload
    end

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

    it 'handles dry run without making changes' do
      expect(deleted_client.deleted?).to be true

      expect do
        described_class.perform_now(
          retained_client_id: retained_client.id,
          deleted_client_id: deleted_client.id,
          dry_run: true,
        )
        deleted_client.reload
      end.to not_change(Hmis::ClientMergeHistory, :count).
        and not_change { deleted_client.deleted? }.from(true)
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

    it 'destroys merge history' do
      merge_history = Hmis::ClientMergeHistory.find_by!(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      expect do
        described_class.perform_now(
          retained_client_id: retained_client.id,
          deleted_client_id: deleted_client.id,
        )
      end.to change(Hmis::ClientMergeHistory, :count).by(-1)

      expect(Hmis::ClientMergeHistory.find_by(id: merge_history.id)).to be_nil
    end

    it 'unlinks clients in search after undo' do
      search_scope = Hmis::Hud::Client.hmis
      results_before = search_scope.text_searcher(deleted_client.id.to_s, sorted: false)
      expect(results_before.pluck(:id)).to include(retained_client.id)

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      results_after = search_scope.text_searcher(deleted_client.id.to_s, sorted: false)
      expect(results_after.pluck(:id)).not_to include(retained_client.id)
      expect(results_after.pluck(:id)).to include(deleted_client.id)
    end

    it 'restores client attributes from pre-merge state' do
      personal_id_before_undo = deleted_client.personal_id

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client.reload
      expect(deleted_client.personal_id).to eq(personal_id_before_undo)
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
      expect(deleted_client_file.reload.client_id).to eq(retained_client.id), 'merge should have moved file to retained client'

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client_file.reload
      expect(deleted_client_file.client_id).to eq(deleted_client.id)
    end

    it 'restores CE referrals to deleted client' do
      expect(deleted_client_ce_referral.reload.client_id).to eq(retained_client.id), 'merge should have moved referral to retained client'

      described_class.perform_now(
        retained_client_id: retained_client.id,
        deleted_client_id: deleted_client.id,
      )

      deleted_client_ce_referral.reload
      expect(deleted_client_ce_referral.client_id).to eq(deleted_client.id)
    end
  end

  describe '#perform with CE enabled' do
    let(:retained_client) { create(:hmis_hud_client_with_warehouse_client, date_created: Time.current - 1.week, data_source: data_source) }
    let(:deleted_client) { create(:hmis_hud_client_with_warehouse_client, date_created: Time.current - 5.days, data_source: data_source) }

    before do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      Hmis::MergeClientsJob.perform_now(
        client_ids: [retained_client.id, deleted_client.id],
        actor_id: actor.id,
      )
      deleted_client.reload
      Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)
    end

    it 'marks the retained client destination as dirty after undo' do
      expect(Hmis::Ce::ChangeMarker.dirty.count).to eq(0)

      expect do
        described_class.perform_now(
          retained_client_id: retained_client.id,
          deleted_client_id: deleted_client.id,
        )
      end.to change { Hmis::Ce::ChangeMarker.dirty.count }.by(1)

      expect(Hmis::Ce::ChangeMarker.sole.trackable).to eq(retained_client.destination_client.as_warehouse)
    end
  end
end
