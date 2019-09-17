require 'rails_helper'

RSpec.describe ClientsController, type: :request do
  let(:destination) { create :window_hud_client }
  let(:client) { create :window_hud_client, SSN: '123456789', FirstName: 'First', LastName: 'Last', DOB: '2019-09-16' }
  let!(:warehouse_client) { create :warehouse_client, source: client, destination: destination }

  describe 'logged out' do
    it 'doesn\'t allow index' do
      get clients_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow show' do
      get client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow new' do
      get new_client_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow create' do
      post clients_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow edit' do
      get edit_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow update' do
      patch client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow service_range' do
      get service_range_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow rollup' do
      get rollup_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow assessment' do
      get assessment_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow image' do
      get image_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow chronic_days' do
      get chronic_days_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow merge' do
      patch merge_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow unmerge' do
      patch unmerge_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'logged in, no permissions' do
    # FIXME: find_client in the controller 404s when there are no data sources visible in the window

    let(:user) { create :user }

    it 'doesn\'t allow index' do
      sign_in user
      get clients_path
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow update' do
      sign_in user
      patch client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(destination, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(destination)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(destination)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end
  end

  describe 'logged in, and can search window' do
    let(:role) { create :can_search_window }
    let(:user) { create :user, roles: [role] }

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to render_template(:index)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow update' do
      sign_in user
      patch client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(client, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to redirect_to(root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(destination, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(destination)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(destination)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end
  end

  # TODO: more permissions
end
