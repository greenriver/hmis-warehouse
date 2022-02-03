###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe ClientAccessControl::ClientsController, type: :request do
  let!(:config) { create :config_b }
  let!(:warehouse_data_source) { create :grda_warehouse_data_source, visible_in_window: true }
  let!(:window_data_source) { create :visible_data_source }
  let!(:destination) { create :grda_warehouse_hud_client, data_source_id: warehouse_data_source.id }
  let!(:client) { create :window_hud_client, data_source_id: window_data_source.id, SSN: '123456789', FirstName: 'First', LastName: 'Last', DOB: '2019-09-16' }
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

    it 'doesn\'t allow service_range' do
      get service_range_client_path(destination)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'doesn\'t allow rollup' do
      get rollup_client_path(destination, partial: :residential_enrollments)
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
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(destination, format: :json)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(destination, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow chronic_days' do
      sign_in user
      get chronic_days_client_path(destination, format: :json)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow merge' do
      sign_in user
      patch merge_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow unmerge' do
      sign_in user
      patch unmerge_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
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
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(destination, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(destination, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
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

  describe 'logged in, and can view client window' do
    # implies 'can_see_this_client_demographics!'
    let(:role) { create :vt_can_view_clients }
    let(:role_search) { create :can_search_window }
    let(:user) { create :user, roles: [role, role_search] }

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'allows show' do
      sign_in user
      get client_path(destination)
      expect(response).to render_template(:show)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows service_range' do
      sign_in user
      get service_range_client_path(destination, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allows rollup' do
      sign_in user
      get rollup_client_path(destination, partial: :residential_enrollments)
      expect(response).to render_template('clients/rollup/_residential_enrollments')
    end

    # through can_see_this_client_demographics
    it 'allows assessment' do
      sign_in user
      form = client.hmis_forms.create(data_source_id: client.data_source_id)
      get assessment_client_path(form, client_id: destination.id)
      expect(response).to have_http_status(200)
    end

    it 'allows image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to have_http_status(403)
    end

    it 'allows chronic_days' do
      sign_in user
      get chronic_days_client_path(destination, format: :json)
      expect(response).to have_http_status(200)
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

  describe 'logged in, and can edit clients' do
    let(:role) { create :can_edit_clients }
    let(:role2) { create :vt_can_view_clients }
    let(:role_search) { create :can_search_window }
    let(:user) { create :user, roles: [role, role2, role_search] }

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'allows show' do
      sign_in user
      get client_path(destination)
      expect(response).to render_template(:show)
    end

    it 'doesn\'t allow new' do
      sign_in user
      get new_client_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow create' do
      sign_in user
      post clients_path
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to render_template(:edit)
    end

    it 'allows service_range' do
      sign_in user
      get service_range_client_path(destination, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allows rollup' do
      sign_in user
      get rollup_client_path(destination, partial: :residential_enrollments)
      expect(response).to render_template('clients/rollup/_residential_enrollments')
    end

    # through can_see_this_client_demographics
    it 'allows assessment' do
      sign_in user
      form = client.hmis_forms.create(data_source_id: client.data_source_id)
      get assessment_client_path(form, client_id: destination.id)
      expect(response).to have_http_status(200)
    end

    it 'allows image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to have_http_status(403)
    end

    it 'allows chronic_days' do
      sign_in user
      get chronic_days_client_path(destination, format: :json)
      expect(response).to have_http_status(200)
    end

    it 'allow merge' do
      sign_in user
      patch merge_client_path(destination, grda_warehouse_hud_client: { merge: [''] })
      expect(response).to redirect_to(edit_client_path(destination.id))
    end

    it 'allow unmerge' do
      sign_in user
      patch unmerge_client_path(destination, grda_warehouse_hud_client: { unmerge: [''] })
      expect(response).to redirect_to(edit_client_path(destination.id))
    end
  end

  describe 'logged in, and can create clients' do
    let(:role) { create :can_create_clients }
    let(:user) { create :user, roles: [role] }

    it 'allows index' do
      sign_in user
      get clients_path
      expect(response).to have_http_status(200)
    end

    it 'doesn\'t allow show' do
      sign_in user
      get client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'allows new' do
      sign_in user
      get new_client_path
      expect(response).to render_template(:new)
    end

    it 'allows create' do
      sign_in user
      post clients_path(client: { data_source_id: window_data_source.id, SSN: '123456789', FirstName: 'First', LastName: 'Last', DOB: '2019-09-16' })
      expect(response).to have_http_status(200)
    end

    it 'doesn\'t allow edit' do
      sign_in user
      get edit_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow service_range' do
      sign_in user
      get service_range_client_path(destination, format: :json)
      follow_redirect!
      expect(response.body).to include('Sorry you are not authorized to do that.')
    end

    it 'doesn\'t allow rollup' do
      sign_in user
      get rollup_client_path(destination, partial: :residential_enrollments)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow assessment' do
      sign_in user
      get assessment_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'doesn\'t allow image' do
      sign_in user
      get image_client_path(destination)
      expect(response).to redirect_to(user.my_root_path)
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
end
