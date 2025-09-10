require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ClientFilesController, type: :request do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  # let!(:access_control) { create_access_control(hmis_user, [p1], with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files]) }
  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:client) { create(:hmis_hud_client, data_source: ds1, user: u1) }
  let!(:nonconfidential_file) do
    create(:file, client: client, user: hmis_user, confidential: false, blob: blob, name: 'Public.pdf')
  end
  let!(:confidential_file) do
    create(:file, client: client, user: hmis_user, confidential: true, blob: blob, name: 'Secret.pdf')
  end

  def request_headers
    { 'ORIGIN' => 'https://hmis.dev.test' }
  end

  describe 'GET /hmis/clients/:client_id/files/:id' do
    context 'when not authenticated' do
      it 'returns 401' do
        get(hmis_client_file_path(client_id: client.id, id: nonconfidential_file.id), headers: request_headers)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { hmis_login(user) }

      it 'returns 404 when file is not attached' do
        file = create(:file, client: client, user: hmis_user, confidential: false, name: 'Empty.pdf', blob: blob)
        get hmis_client_file_path(client_id: client.id, id: file.id), headers: request_headers
        expect(response).to have_http_status(:not_found)
      end

      it 'redirects (302) for nonconfidential file with permissions' do
        get hmis_client_file_path(client_id: client.id, id: nonconfidential_file.id), headers: request_headers
        expect(response).to have_http_status(:found)
        expect(response.headers['Location']).to be_present
      end

      it 'returns 404 for confidential file without confidential permission' do
        get hmis_client_file_path(client_id: client.id, id: confidential_file.id), headers: request_headers
        expect(response).to have_http_status(:not_found)
      end

      context 'with confidential view permission' do
        before do
          add_permissions(access_control, :can_view_any_confidential_client_files)
        end

        it 'redirects (302) for confidential file' do
          get hmis_client_file_path(client_id: client.id, id: confidential_file.id), headers: request_headers
          expect(response).to have_http_status(:found)
          expect(response.headers['Location']).to be_present
        end
      end

      context 'with manage-own-files permission and ownership' do
        before do
          add_permissions(access_control, :can_manage_own_client_files)
        end

        it 'redirects (302) for user-owned confidential file' do
          owned_confidential = create(:file, client: client, user: hmis_user, confidential: true, blob: blob)
          get hmis_client_file_path(client_id: client.id, id: owned_confidential.id), headers: request_headers
          expect(response).to have_http_status(:found)
          expect(response.headers['Location']).to be_present
        end
      end
    end
  end
end
