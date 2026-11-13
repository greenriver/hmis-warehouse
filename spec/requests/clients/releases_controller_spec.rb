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

  def zip_entry_names(body)
    entry_names = []
    Zip::InputStream.open(StringIO.new(body)) do |zip|
      while (entry = zip.get_next_entry)
        entry_names << entry.name
      end
    end
    entry_names
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
      # update only accepts the consent fields, none of which can fail validation on a revocation, so an invalid
      # row stands in for any save failure; the revocation must still roll back with it
      file.update_columns(visible_in_window: nil)

      revoke

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

      update_release(pending_release, { consent_form_confirmed: '1', consent_form_signed_on: 3.days.ago.to_date.to_s })

      expect(response).to have_http_status(:ok)
      pending_release.reload
      expect(pending_release.consent_form_signed_on).to eq(3.days.ago.to_date)
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

    context 'when consent forms are visible to all and the release belongs to another user' do
      let!(:other_release) do
        create :client_file, client: client, tags: [consent_tag], effective_date: 2.days.ago, note: 'Original note'
      end

      before do
        GrdaWarehouse::Config.first.update!(consent_visible_to_all: true)
        GrdaWarehouse::Config.invalidate_cache
      end

      it 'changes only the consent fields' do
        update_release(
          other_release,
          {
            expiration_date: 1.year.from_now.to_date.to_s,
            note: 'Changed',
            tag_list: ['Other Document'],
            coc_codes: ['XX-500'],
            visible_in_window: '0',
          },
        )

        expect(response).to have_http_status(:ok)
        other_release.reload
        expect(other_release.expiration_date).to eq(1.year.from_now.to_date)
        expect(other_release.note).to eq('Original note')
        expect(other_release.tag_list).to eq([consent_tag.name])
        expect(other_release.coc_codes).to be_blank
        expect(other_release.visible_in_window).to be true
      end
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

  describe 'confidential consent forms' do
    let!(:hidden_project) { create :hud_project }
    let!(:confidential_release) do
      create :client_file,
             client: client,
             tags: [consent_tag],
             effective_date: 2.days.ago,
             confidential: true,
             data_source: hidden_project.data_source,
             note: 'Hidden note'
    end

    it 'renders the index with the confidential form redacted' do
      get client_releases_path(client_id: client.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("client-file-#{confidential_release.id}")
      expect(response.body).not_to include('Hidden note')
    end

    # The release upload form has no confidentiality fields, so file_params doesn't permit them
    it 'ignores confidentiality params on upload' do
      file_upload = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')

      expect do
        post client_releases_path(client_id: client.id), params: {
          grda_warehouse_client_file: {
            client_file: file_upload,
            tag_list: [consent_tag.name],
            effective_date: Date.current,
            confidential: '1',
            data_source_id: hidden_project.data_source_id,
            coc_codes: [''],
          },
        }
      end.to change(GrdaWarehouse::ClientFile, :count).by(1)

      file = GrdaWarehouse::ClientFile.order(:id).last
      expect(file.confidential).to be false
      expect(file.data_source_id).to be_nil
    end

    it 'returns not found for a download' do
      get client_release_path(client_id: client.id, id: confidential_release.id)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a preview' do
      get preview_client_release_path(client_id: client.id, id: confidential_release.id)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a confirmation and leaves the form unconfirmed' do
      update_release(confidential_release, { consent_form_confirmed: '1' })

      expect(response).to have_http_status(:not_found)
      expect(confidential_release.reload.consent_form_confirmed).to be_falsey
    end

    it 'returns not found for a revocation of the active release and leaves consent in place' do
      confidential_release.confirm_consent!
      expect(client.reload.consent_form_id).to eq(confidential_release.id)

      update_release(confidential_release, { consent_revoked_at: Date.current.to_s })

      expect(response).to have_http_status(:not_found)
      expect(confidential_release.reload.consent_revoked_at).to be_nil
      client.reload
      expect(client.consent_form_id).to eq(confidential_release.id)
      expect(client.housing_release_status).to eq(GrdaWarehouse::Hud::Client.full_release_string)
      expect(roi_row.status).to eq('full')
    end

    it 'leaves the confidential form out of a batch download' do
      file_ids = [file.id, confidential_release.id].join(',')
      post batch_download_client_releases_path(client_id: client.id), params: { batch_download: { file_ids: file_ids } }

      expect(response).to have_http_status(:ok)
      expect(zip_entry_names(response.body)).to eq([File.join(client.id.to_s, "#{file.tag_list.join('-')}.jpg")])
    end

    context 'for a user with confidential access at its data source' do
      before do
        grant_project_access(user, create(:role, can_see_confidential_files: true), [hidden_project], mode: :acl)
      end

      it 'downloads the form' do
        get client_release_path(client_id: client.id, id: confidential_release.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(confidential_release.client_file.download)
      end

      it 'renders the index with the confidential form details' do
        get client_releases_path(client_id: client.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Hidden note')
      end

      it 'includes the confidential form in a batch download' do
        # Entries are named by tags and rubyzip collapses duplicate names, so give the form a distinct name
        confidential_release.update!(tag_list: [consent_tag.name, 'Signed Copy'])
        file_ids = [file.id, confidential_release.id].join(',')
        post batch_download_client_releases_path(client_id: client.id), params: { batch_download: { file_ids: file_ids } }

        expect(response).to have_http_status(:ok)
        expect(zip_entry_names(response.body)).to contain_exactly(
          File.join(client.id.to_s, "#{file.tag_list.join('-')}.jpg"),
          File.join(client.id.to_s, "#{confidential_release.reload.tag_list.join('-')}.jpg"),
        )
      end
    end

    context 'for a legacy-permission user with can_see_confidential_files' do
      let!(:legacy_user) { create :user }

      before do
        legacy_role = create :role,
                             can_manage_client_files: true,
                             can_confirm_housing_release: true,
                             can_use_separated_consent: true,
                             can_search_all_clients: true,
                             can_see_confidential_files: true
        grant_project_access(legacy_user, legacy_role, [hidden_project], mode: :legacy)
        sign_in legacy_user
      end

      it 'returns not found for a download' do
        get client_release_path(client_id: client.id, id: confidential_release.id)
        expect(response).to have_http_status(:not_found)
      end

      it 'leaves the form out of a batch download' do
        file_ids = [file.id, confidential_release.id].join(',')
        post batch_download_client_releases_path(client_id: client.id), params: { batch_download: { file_ids: file_ids } }

        expect(response).to have_http_status(:ok)
        expect(zip_entry_names(response.body)).to eq([File.join(client.id.to_s, "#{file.tag_list.join('-')}.jpg")])
      end
    end
  end
end
