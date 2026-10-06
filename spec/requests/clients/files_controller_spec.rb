###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::FilesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:client) { warehouse_client.destination }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:can_manage_client_files) do
    create :role, can_manage_client_files: true, can_confirm_housing_release: true, can_see_own_file_uploads: true, can_search_own_clients: true
  end

  def grant_client_access(user, role)
    collection = create(:collection)
    collection.set_viewables({ data_sources: [warehouse_client.source.data_source_id] })
    setup_access_control(user, role, collection)
  end

  before(:each) do
    sign_in user
    grant_client_access(user, can_manage_client_files)
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  describe 'POST #create' do
    let(:file_upload) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
    end

    context 'when auto_confirm_consent is enabled' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, auto_confirm_consent: true
        GrdaWarehouse::Config.invalidate_cache
      end

      it 'automatically confirms the consent form even when consent_form_confirmed is not set' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '0',
            coc_codes: [''],
          },
        }
        expect(response).to have_http_status(:redirect)
        expect(GrdaWarehouse::Config.get(:auto_confirm_consent)).to be true
        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
        expect(GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)&.status).to eq('full')
      end

      it 'user is able to confirm the consent form' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '1',
            coc_codes: [''],
          },
        }

        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
      end
    end

    context 'when auto_confirm_consent is disabled' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, auto_confirm_consent: false
        GrdaWarehouse::Config.invalidate_cache
      end

      it 'does not automatically confirm the consent form' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '0',
            coc_codes: [''],
          },
        }
        expect(GrdaWarehouse::Config.get(:auto_confirm_consent)).to be false
        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be false
        expect(file.client.consent_form_valid?).to be false
      end

      it 'user is able to confirm the consent form' do
        post client_files_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            consent_form_confirmed: '1',
            coc_codes: [''],
          },
        }

        file = GrdaWarehouse::ClientFile.last
        expect(file.consent_form_confirmed).to be true
        expect(file.client.consent_form_valid?).to be true
      end
    end

    context 'under a Use Expiration Date release duration' do
      before do
        GrdaWarehouse::Config.delete_all
        create :config_b, release_duration: 'Use Expiration Date'
        GrdaWarehouse::Config.invalidate_cache
      end

      it 're-renders the form and saves nothing when a confirmed consent form has no expiration date' do
        expect do
          post client_files_path(client_id: client.id), params: {
            grda_warehouse_client_file: {
              client_file: file_upload,
              tag_list: [consent_tag.name],
              effective_date: Date.current,
              consent_form_confirmed: '1',
              coc_codes: [''],
            },
          }
        end.not_to change(GrdaWarehouse::ClientFile, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Expiration date is required')
        expect(client.reload.consent_form_id).to be_nil
        expect(GrdaWarehouse::ClientRoiAuthorization.where(destination_client_id: client.id)).to be_empty
      end
    end
  end

  describe 'consent revocation and deletion' do
    let!(:file) do
      create :client_file, client: client, tags: [consent_tag], effective_date: 5.days.ago, expiration_date: 1.year.from_now.to_date
    end

    def use_config(roi_model, release_duration)
      GrdaWarehouse::Config.delete_all
      create :config_b, roi_model: roi_model, release_duration: release_duration
      GrdaWarehouse::Config.invalidate_cache
    end

    def roi_row
      GrdaWarehouse::ClientRoiAuthorization.find_by(destination_client_id: client.id)
    end

    def revoke_consent_form
      patch client_file_path(client_id: client.id, id: file.id),
            params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
            xhr: true
      expect(response).to have_http_status(:ok)
    end

    def run_nightly_rebuild
      GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [client.id])
    end

    ['Indefinite', 'Use Expiration Date', 'One Year', 'Two Years'].each do |release_duration|
      context "under implied consent with a #{release_duration} release duration" do
        before do
          use_config(:implicit, release_duration)
          file.confirm_consent!
        end

        it 'keeps the client marked revoked, with a revoked ROI row, through the nightly rebuild' do
          expect(roi_row.status).to eq('full')

          revoke_consent_form
          expect(roi_row.status).to eq('revoked')
          run_nightly_rebuild

          client.reload
          expect(client.housing_release_status).to eq(Consent::Implied.revoked_consent_string)
          expect(roi_row.status).to eq('revoked')
          expect(client.full_or_partial_release?).to be false
          expect(GrdaWarehouse::Hud::Client.consent_form_valid.where(id: client.id)).to be_empty
        end
      end
    end

    context 'under default consent' do
      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'clears the release and removes the ROI row when the request completes' do
        expect(roi_row.status).to eq('full')

        revoke_consent_form

        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end

      it 'keeps the release and the ROI row when the revoked file fails validation' do
        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s, confidential: '1', data_source_id: '', enrollment_id: '' } },
              xhr: true

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Data source', 'blank')
        expect(file.reload.consent_revoked_at).to be_nil
        expect(client.reload.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end
    end

    context 'when the user can manage files but cannot confirm releases' do
      let!(:file_manager) { create :acl_user }

      before do
        use_config(:explicit, 'Indefinite')
        grant_client_access(file_manager, create(:role, can_manage_client_files: true, can_see_own_file_uploads: true, can_search_own_clients: true))
        sign_in file_manager
      end

      it 'saves the other changes but leaves the consent form unconfirmed, with no ROI row' do
        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_form_confirmed: '1', note: 'Reviewed' } },
              xhr: true

        expect(response).to have_http_status(:ok)
        file.reload
        expect(file.note).to eq('Reviewed')
        expect(file.consent_form_confirmed).to be_nil
        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end
    end

    context 'when the user cannot search for the client' do
      let!(:outsider) { create :acl_user }

      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
        # Same permissions as the file manager, through a collection that holds no data sources
        setup_access_control(outsider, create(:role, can_manage_client_files: true, can_confirm_housing_release: true, can_see_own_file_uploads: true, can_search_own_clients: true), create(:collection))
        sign_in outsider
      end

      it 'returns not found for a revocation and leaves the consent in place' do
        patch client_file_path(client_id: client.id, id: file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(file.reload.consent_revoked_at).to be_nil
        expect(client.reload.consent_form_id).to eq(file.id)
        expect(roi_row.status).to eq('full')
      end

      it 'returns not found for a deletion and leaves the consent in place' do
        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: file.id)).to exist
        expect(client.reload.consent_form_id).to eq(file.id)
        expect(roi_row.status).to eq('full')
      end
    end

    context "when the request names another client's consent form" do
      let!(:other_client) { create :grda_warehouse_hud_client }
      let!(:other_file) { create :client_file, client: other_client, tags: [consent_tag], effective_date: 5.days.ago }

      before do
        use_config(:explicit, 'Indefinite')
        other_file.confirm_consent!
      end

      it 'returns not found for a revocation and leaves the other client consent in place' do
        patch client_file_path(client_id: client.id, id: other_file.id),
              params: { grda_warehouse_client_file: { consent_revoked_at: Date.current.to_s } },
              xhr: true

        expect(response).to have_http_status(:not_found)
        expect(other_file.reload.consent_revoked_at).to be_nil
        expect(other_client.reload.consent_form_id).to eq(other_file.id)
      end

      it 'returns not found for a deletion and leaves the other client consent in place' do
        delete client_file_path(client_id: client.id, id: other_file.id)

        expect(response).to have_http_status(:not_found)
        expect(GrdaWarehouse::ClientFile.where(id: other_file.id)).to exist
        expect(other_client.reload.consent_form_id).to eq(other_file.id)
      end
    end

    describe 'DELETE #destroy' do
      before do
        use_config(:explicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'removes the ROI row when the active consent form is deleted' do
        expect(roi_row.status).to eq('full')

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(client.reload.housing_release_status).to be_nil
        expect(roi_row).to be_nil
      end

      it 'keeps the file, the release, and the ROI row when the active consent form fails validation on delete' do
        file.update_columns(confidential: true, data_source_id: nil, enrollment_id: nil)

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(flash[:error]).to eq('File could not be deleted.')
        expect(GrdaWarehouse::ClientFile.where(id: file.id)).to exist
        client.reload
        expect(client.consent_form_id).to eq(file.id)
        expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end

      it 'keeps the release and the ROI row when an older, unconfirmed consent form is deleted' do
        older_form = create :client_file, client: client, tags: [consent_tag], effective_date: 1.year.ago

        delete client_file_path(client_id: client.id, id: older_form.id)

        expect(GrdaWarehouse::ClientFile.where(id: older_form.id)).to be_empty
        client.reload
        expect(client.consent_form_id).to eq(file.id)
        expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
        expect(roi_row.status).to eq('full')
      end
    end

    describe 'DELETE #destroy under implied consent' do
      before do
        use_config(:implicit, 'Indefinite')
        file.confirm_consent!
      end

      it 'falls back to implied consent with a partial ROI row when the active consent form is deleted' do
        expect(roi_row.status).to eq('full')

        delete client_file_path(client_id: client.id, id: file.id)

        expect(response).to redirect_to(client_files_path(client_id: client.id))
        expect(client.reload.housing_release_status).to eq(Consent::Implied.no_release_string)
        expect(roi_row.status).to eq('partial')
      end
    end
  end
end
