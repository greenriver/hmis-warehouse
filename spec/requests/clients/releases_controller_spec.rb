###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::ReleasesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:client) { warehouse_client.destination }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:file) do
    create :client_file, client: client, tags: [consent_tag], effective_date: 5.days.ago, expiration_date: 1.year.from_now.to_date
  end
  let(:roi_model) { :explicit }

  def grant_client_access(user, role)
    collection = create(:collection)
    collection.set_viewables({ data_sources: [warehouse_client.source.data_source_id] })
    setup_access_control(user, role, collection)
  end

  before do
    GrdaWarehouse::Config.delete_all
    create :config_b, roi_model: roi_model, release_duration: 'Indefinite'
    GrdaWarehouse::Config.invalidate_cache

    sign_in user
    grant_client_access(user, create(:role, can_manage_client_files: true, can_confirm_housing_release: true, can_use_separated_consent: true, can_search_own_clients: true))
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
    file.confirm_consent!
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  def roi_row
    GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
  end

  def revoke(extra_params = {})
    patch client_release_path(client_id: client.id, id: file.id),
          params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s }.merge(extra_params) },
          xhr: true
  end

  def update_release(release, attrs)
    patch client_release_path(client_id: client.id, id: release.id),
          params: { grda_warehouse_client_file: attrs },
          xhr: true
  end

  describe 'PATCH #update' do
    it 'clears the release and removes the ROI row when the consent form is revoked' do
      expect(roi_row.status).to eq('full')

      revoke

      expect(file.reload.consent_revoked_at.to_date).to eq(Date.current)
      expect(client.reload.housing_release_status).to be_nil
      expect(roi_row).to be_nil
    end

    it 'keeps the release and the ROI row when the revoked file fails validation' do
      revoke(visible_in_window: '')

      expect(file.reload.consent_revoked_at).to be_nil
      expect(client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
      expect(roi_row.status).to eq('full')
    end
  end

  context 'when the user can use separated consent but cannot manage files or confirm releases' do
    let!(:separated_user) { create :acl_user }
    let!(:file) do
      create :client_file, client: client, user: separated_user, tags: [consent_tag], effective_date: 5.days.ago, expiration_date: 1.year.from_now.to_date
    end

    before do
      grant_client_access(separated_user, create(:role, can_use_separated_consent: true, can_see_own_file_uploads: true, can_search_own_clients: true))
      sign_in separated_user
    end

    it 'saves the other changes but leaves a new release unconfirmed and the active release unchanged' do
      pending_release = create :client_file, client: client, user: separated_user, tags: [consent_tag], effective_date: 2.days.ago

      update_release(pending_release, { consent_form_confirmed: '1', note: 'Reviewed' })

      expect(response).to have_http_status(:ok)
      pending_release.reload
      expect(pending_release.note).to eq('Reviewed')
      expect(pending_release.consent_form_confirmed).to be_nil
      expect(client.reload.consent_form_id).to eq(file.id)
    end

    it 'restores the release and the full ROI row when the user clears the revocation' do
      revoke
      expect(roi_row).to be_nil

      update_release(file, { consent_revoked_at: '' })

      expect(response).to have_http_status(:ok)
      expect(file.reload.consent_revoked_at).to be_nil
      client.reload
      expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
      expect(client.consent_form_id).to eq(file.id)
      expect(roi_row.status).to eq('full')
    end

    it 'clears the release and removes the ROI row when the user deletes the active release' do
      expect(roi_row.status).to eq('full')

      delete client_release_path(client_id: client.id, id: file.id)

      expect(GrdaWarehouse::ClientFile.where(id: file.id)).to be_empty
      expect(client.reload.housing_release_status).to be_nil
      expect(client.consent_form_id).to be_nil
      expect(roi_row).to be_nil
    end

    context 'without a file permission' do
      before do
        separated_only = create :acl_user
        grant_client_access(separated_only, create(:role, can_use_separated_consent: true, can_search_own_clients: true))
        file.update!(user: separated_only)
        sign_in separated_only
      end

      it 'returns not found for a deletion of their own release and leaves the consent in place' do
        delete client_release_path(client_id: client.id, id: file.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: file.id)).to exist
        expect(client.reload.consent_form_id).to eq(file.id)
        expect(roi_row.status).to eq('full')
      end
    end

    context "when the request names another client's release" do
      let!(:other_client) { create :grda_warehouse_hud_client }
      let!(:other_release) { create :client_file, client: other_client, user: separated_user, tags: [consent_tag], effective_date: 5.days.ago }

      before { other_release.confirm_consent! }

      it 'returns not found for a revocation and leaves the other client consent in place' do
        update_release(other_release, { consent_revoked_at: Date.current.to_s })

        expect(response).to have_http_status(:not_found)
        expect(other_release.reload.consent_revoked_at).to be_nil
        expect(other_client.reload.consent_form_id).to eq(other_release.id)
      end

      it 'returns not found for a deletion and leaves the other client consent in place' do
        delete client_release_path(client_id: client.id, id: other_release.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: other_release.id)).to exist
        expect(other_client.reload.consent_form_id).to eq(other_release.id)
      end
    end

    context 'under implied consent' do
      let(:roi_model) { :implicit }

      it 'marks the client revoked, with a revoked ROI row, when the request completes' do
        expect(roi_row.status).to eq('full')

        revoke

        expect(response).to have_http_status(:ok)
        expect(client.reload.housing_release_status).to eq(Consent::Implied.revoked_consent_string)
        expect(roi_row.status).to eq('revoked')
      end
    end
  end
end
