# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AppConfigPropertiesController, type: :request do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role }
  let!(:no_data_source_collection) { create :collection }

  describe 'GET #index' do
    context 'with authorized user' do
      before(:each) do
        setup_access_control(user, role, no_data_source_collection)
        sign_in user
      end

      it 'returns http success' do
        get admin_app_config_properties_path
        expect(response).to have_http_status(:success)
      end

      it 'displays existing app config properties' do
        create(:app_config_property, key: 'test_key', value: 'test_value')
        get admin_app_config_properties_path
        expect(response.body).to include('test_key')
        expect(response.body).to include('test_value')
      end
    end

    context 'with unauthorized user' do
      before(:each) do
        sign_in user
      end

      it 'redirects' do
        get admin_app_config_properties_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'POST #create' do
    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { key: 'new_key', value: 'new_value' } }

      it 'creates app config property' do
        expect do
          post admin_app_config_properties_path, params: { app_config_property: valid_attrs }
        end.to change(AppConfigProperty, :count).by(1)
      end

      it 'redirects to index' do
        post admin_app_config_properties_path, params: { app_config_property: valid_attrs }
        expect(response).to redirect_to(admin_app_config_properties_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { key: '', value: '' } }

      it 'does not create app config property' do
        expect do
          post admin_app_config_properties_path, params: { app_config_property: invalid_attrs }
        end.not_to change(AppConfigProperty, :count)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:property) { create(:app_config_property) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    context 'with valid attributes' do
      let(:valid_attrs) { { value: 'updated_value' } }

      it 'updates the app config property' do
        patch admin_app_config_property_path(property), params: { app_config_property: valid_attrs }
        property.reload
        expect(property.value).to eq('updated_value')
      end

      it 'redirects to index' do
        patch admin_app_config_property_path(property), params: { app_config_property: valid_attrs }
        expect(response).to redirect_to(admin_app_config_properties_path)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attrs) { { key: '' } } # Key is required and disabled in form but let's test controller validation

      it 'does not update the app config property key' do
        original_key = property.key
        patch admin_app_config_property_path(property), params: { app_config_property: invalid_attrs }
        property.reload
        expect(property.key).to eq(original_key)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:property) { create(:app_config_property) }

    before(:each) do
      setup_access_control(user, role, no_data_source_collection)
      sign_in user
    end

    it 'deletes the app config property' do
      expect do
        delete admin_app_config_property_path(property)
      end.to change(AppConfigProperty, :count).by(-1)
    end

    it 'redirects to index' do
      delete admin_app_config_property_path(property)
      expect(response).to redirect_to(admin_app_config_properties_path)
    end
  end
end
