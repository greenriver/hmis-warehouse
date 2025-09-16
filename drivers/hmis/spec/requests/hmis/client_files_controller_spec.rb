# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ClientFilesController, type: :request do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  let!(:access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_any_nonconfidential_client_files,
      ],
    )
  end

  let!(:nonconfidential_file) do
    create(:file, client: c1, user: hmis_user, confidential: false, blob: blob, name: 'Public.pdf')
  end

  let!(:user2) { create(:user) }
  let(:hmis_user2) { user2.related_hmis_user(ds1) }

  let!(:confidential_file) do
    create(:file, client: c1, user: hmis_user2, confidential: true, blob: blob, name: 'Secret.pdf')
  end

  def request_headers
    { 'ORIGIN' => 'https://hmis.dev.test' }
  end

  ACTIVE_STORAGE_URL_REGEX = /\Ahttps?:\/\/[^\/]+\/rails\/active_storage\/(disk|blobs)\//

  def get_file_path_for(file_id, params: {})
    get hmis_client_file_path(client_id: c1.id, id: file_id), params: params, headers: request_headers
  end

  def expect_active_storage_redirect
    expect(response).to have_http_status(:found)
    location = response.headers['Location']
    expect(location).to be_present
    expect(location).to match(ACTIVE_STORAGE_URL_REGEX)
    location
  end

  describe 'GET /hmis/clients/:client_id/files/:id' do
    context 'when not authenticated' do
      it 'returns 401' do
        get(hmis_client_file_path(client_id: c1.id, id: nonconfidential_file.id), headers: request_headers)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before do
        host! 'hmis.dev.test'
        https!
        hmis_login(user)
        allow(ActiveStorage::Current).to receive(:url_options).and_return({ host: 'hmis.dev.test', protocol: 'https' })
      end

      it 'returns 404 when file is not attached' do
        file = build(:file, client: c1, user: hmis_user, confidential: false, name: 'Empty.pdf', blob: nil)
        file.save!(validate: false)
        get hmis_client_file_path(client_id: c1.id, id: file.id), headers: request_headers
        expect(response).to have_http_status(:not_found)
      end

      it 'redirects to an ActiveStorage service URL for nonconfidential file' do
        get_file_path_for(nonconfidential_file.id)
        expect_active_storage_redirect
      end

      it 'uses X-Forwarded-Host when Origin is missing' do
        headers = { 'X-Forwarded-Host' => 'hmis.dev.test' }
        get hmis_client_file_path(client_id: c1.id, id: nonconfidential_file.id), headers: headers
        expect_active_storage_redirect
      end

      it 'raises when Origin and X-Forwarded-Host are missing ' do
        expect do
          get hmis_client_file_path(client_id: c1.id, id: nonconfidential_file.id)
        end.to raise_error(RuntimeError, 'cannot determine HMIS host (no Origin, X-Forwarded-Host)')
      end

      it 'creates an HMIS activity log with client reference and file variables' do
        expect do
          get_file_path_for(nonconfidential_file.id)
        end.to change(Hmis::ActivityLog, :count).by(1)

        log = Hmis::ActivityLog.order(:id).last
        expect(log.operation_name).to eq('ClientFileRedirect')
        # resolved_fields keys drive processing; values are ignored by the processor
        expect(log.resolved_fields).to be_a(Hash)
        expect(log.resolved_fields).to have_key("Client/#{c1.id}")
        # variables are metadata for correlation
        expect(log.variables).to include('fileId' => nonconfidential_file.id, 'clientId' => c1.id)
        expect(log.user_id).to eq(hmis_user.id)
        expect(log.data_source_id).to eq(ds1.id)
      end

      it 'respects disposition=attachment in final response headers' do
        get_file_path_for(nonconfidential_file.id, params: { disposition: 'attachment' })
        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.headers['Content-Disposition']).to include('attachment')
      end

      it 'defaults to inline disposition when param is missing' do
        get_file_path_for(nonconfidential_file.id)
        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.headers['Content-Disposition']).to include('inline')
      end

      it 'returns 404 when file belongs to a different client' do
        other_client = create(:hmis_hud_client, data_source: ds1, user: u1)
        other_clients_file = create(:file, client: other_client, user: hmis_user, confidential: false, blob: blob)

        get hmis_client_file_path(client_id: c1.id, id: other_clients_file.id), headers: request_headers
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for confidential file without confidential permission' do
        remove_permissions(access_control, :can_view_any_confidential_client_files)
        expect do
          get hmis_client_file_path(client_id: c1.id, id: confidential_file.id), headers: request_headers
        end.not_to change(Hmis::ActivityLog, :count)
        expect(response).to have_http_status(:not_found)
      end

      context 'with confidential view permission' do
        before do
          add_permissions(access_control, :can_view_any_confidential_client_files)
        end

        it 'redirects to an ActiveStorage service URL for confidential file' do
          get_file_path_for(confidential_file.id)
          expect_active_storage_redirect
        end
      end

      context 'with manage-own-files permission and ownership' do
        before do
          add_permissions(access_control, :can_manage_own_client_files)
        end

        it 'redirects to an ActiveStorage service URL for user-owned confidential file' do
          owned_confidential = create(:file, client: c1, user: hmis_user, confidential: true, blob: blob)
          get_file_path_for(owned_confidential.id)
          expect_active_storage_redirect
        end
      end
    end
  end
end
