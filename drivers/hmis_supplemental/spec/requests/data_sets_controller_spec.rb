# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisSupplemental::DataSetsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:data_source) { create(:hmis_data_source) }
  let(:data_set) { create(:hmis_supplemental_data_set, data_source: data_source) }
  let(:role) { create(:role, can_manage_config: true, can_edit_data_sources: true, can_view_projects: true) }
  let(:user_group) { create(:user_group) }
  let(:collection) { Collection.system_collection(:data_sources) }

  before(:each) do
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get data_source_hmis_supplemental_data_sets_path(data_source)
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'returns http success' do
      get new_data_source_hmis_supplemental_data_set_path(data_source)
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        data_set: {
          name: 'Test Data Set',
          object_key: 'test.csv',
          owner_type: 'client',
          field_config: '[{"key":"widget","type":"float","label":"The Widget","multiValued":false}]',
          sync_enabled: true,
          remote_credential_attributes: {
            region: 'us-east-1',
            bucket: 'test-bucket',
            s3_access_key_id: 'test-key',
            s3_secret_access_key: 'test-secret',
            s3_prefix: 'test/',
          },
        },
      }
    end

    it 'creates a new data set' do
      expect do
        post data_source_hmis_supplemental_data_sets_path(data_source), params: valid_params
      end.to change(HmisSupplemental::DataSet, :count).by(1)
      expect(response).to redirect_to(data_source_hmis_supplemental_data_sets_path)
    end
  end

  describe 'GET #edit' do
    it 'returns http success' do
      get edit_data_source_hmis_supplemental_data_set_path(data_source, data_set)
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        data_set: {
          name: 'Updated Data Set',
        },
      }
    end

    it 'updates the data set' do
      patch data_source_hmis_supplemental_data_set_path(data_source, data_set), params: update_params
      expect(response).to redirect_to(data_source_hmis_supplemental_data_sets_path)
      expect(data_set.reload.name).to eq('Updated Data Set')
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the data set' do
      url = data_source_hmis_supplemental_data_set_path(data_source, data_set)
      expect { delete url }.to change(HmisSupplemental::DataSet, :count).by(-1)
      expect(response).to redirect_to(data_source_hmis_supplemental_data_sets_path)
    end
  end
end
