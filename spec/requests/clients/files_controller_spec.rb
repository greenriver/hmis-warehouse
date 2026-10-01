###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::FilesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
  let!(:no_data_source_collection) { create :collection }
  let!(:can_manage_client_files) { create :role, can_manage_client_files: true, can_confirm_housing_release: true }

  before(:each) do
    sign_in user
    setup_access_control(user, can_manage_client_files, no_data_source_collection)
    allow_any_instance_of(Clients::FilesController).to receive(:destination_searchable_client_scope).and_return(
      GrdaWarehouse::Hud::Client.where(id: client.id),
    )
    allow_any_instance_of(Clients::FilesController).to receive(:require_window_file_access!).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:can_manage_client_files?).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:can_confirm_housing_release?).and_return(true)
    allow_any_instance_of(Clients::FilesController).to receive(:window_visible?).and_return(true)
    allow_any_instance_of(GrdaWarehouse::ClientFile).to receive(:file_exists_and_not_too_large).and_return(true)
  end

  describe 'POST #create' do
    let(:file_upload) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
    end

    context 'when auto_confirm_consent is enabled' do
      before do
        config = GrdaWarehouse::Config.first_or_create
        config.update!(auto_confirm_consent: true)
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
        config = GrdaWarehouse::Config.first_or_create
        config.update!(auto_confirm_consent: false)
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
  end

  describe 'consent revocation and deletion' do
    let!(:client) { create :grda_warehouse_hud_client, data_source: create(:destination_data_source) }
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
    end
  end
end
