require 'rails_helper'

RSpec.describe SourceClientsController, type: :request do
  let(:destination) { create :grda_warehouse_hud_client }
  let(:client) { create :grda_warehouse_hud_client, SSN: '123456789', FirstName: 'First', LastName: 'Last', DOB: '2019-09-16' }
  let!(:warehouse_client) { create :warehouse_client, source: client, destination: destination }

  describe 'logged out' do
    it 'doesn\'t allow edit' do
      get edit_source_client_path(client)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow update' do
      patch source_client_path(client)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow image' do
      get image_source_client_path(client)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow destination' do
      get destination_source_client_path(client)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'logged in, but can\'t create clients' do
    let(:user) { create :user }

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_source_client_path(client)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow update' do
      sign_in user
      patch source_client_path(client)
      expect(response).to redirect_to(root_path)
    end

    it 'image forbidden' do
      sign_in user
      get image_source_client_path(client)
      expect(response).to have_http_status(403)
    end

    it 'doesn\'t allow destination' do
      sign_in user
      get destination_source_client_path(client)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'logged in, and can create clients' do
    let(:role) { create :can_create_clients }
    let(:user) { create :user, roles: [role] }

    it 'allows edit' do
      sign_in user
      get edit_source_client_path(client)
      expect(response).to render_template(:edit)
    end

    it 'allows update' do
      sign_in user
      patch source_client_path(client), params: {
        client: {
          SSN: '123456789',
          FirstName: 'First',
          LastName: 'Last',
          DOB: '2019-09-16',
        },
      }
      expect(response).to redirect_to(client_path(destination))
    end

    it 'image forbidden' do
      sign_in user
      get image_source_client_path(client)
      expect(response).to have_http_status(403)
    end

    it 'allows destination' do
      sign_in user
      get destination_source_client_path(client)
      expect(response).to redirect_to(client_path(destination))
    end
  end
end
