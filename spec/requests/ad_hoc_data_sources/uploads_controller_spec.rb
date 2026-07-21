###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdHocDataSources::UploadsController, type: :request do
  let(:role) { create(:role, can_manage_ad_hoc_data_sources: true) }
  let(:user) do
    u = create(:user)
    u.legacy_roles << role
    u
  end
  let(:data_source) { create(:ad_hoc_data_source) }

  before { sign_in user }

  describe 'GET #download' do
    it 'downloads using the ActiveStorage attachment when batch_file is present' do
      upload = create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source)

      get download_ad_hoc_data_source_upload_path(data_source, upload)

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('initial_batch.csv')
      expect(response.content_type).to eq('text/csv')
      expect(response.body).to eq(File.binread(Rails.root.join('spec/fixtures/files/ad_hoc_batches/initial_batch.csv')))
    end

    it 'downloads using the legacy content column when no batch_file is attached' do
      upload = GrdaWarehouse::AdHocBatch.new(
        description: 'Legacy Batch',
        ad_hoc_data_source: data_source,
        content: 'legacy,csv,content',
        content_type: 'text/csv',
        file: 'legacy_upload.csv',
      )
      upload.save!(validate: false)

      get download_ad_hoc_data_source_upload_path(data_source, upload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('legacy,csv,content')
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('Legacy Batch')
    end

    context 'when the user lacks the ad-hoc management permission' do
      let(:role) { create(:role, can_manage_ad_hoc_data_sources: false, can_manage_own_ad_hoc_data_sources: false) }

      it 'denies access' do
        upload = create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source)

        get download_ad_hoc_data_source_upload_path(data_source, upload)

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when the user can only manage their own ad hoc data sources' do
      let(:role) { create(:role, can_manage_ad_hoc_data_sources: false, can_manage_own_ad_hoc_data_sources: true) }
      let(:own_data_source) { create(:ad_hoc_data_source, user_id: user.id) }
      let(:other_users_data_source) { create(:ad_hoc_data_source, user_id: create(:user).id) }

      it 'allows downloading an upload under their own data source' do
        upload = create(:ad_hoc_batch_valid, ad_hoc_data_source: own_data_source)

        get download_ad_hoc_data_source_upload_path(own_data_source, upload)

        expect(response).to have_http_status(:ok)
      end

      it 'denies downloading an upload under another user\'s data source' do
        upload = create(:ad_hoc_batch_valid, ad_hoc_data_source: other_users_data_source)

        get download_ad_hoc_data_source_upload_path(other_users_data_source, upload)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
