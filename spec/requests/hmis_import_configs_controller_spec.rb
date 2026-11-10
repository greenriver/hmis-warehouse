###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisImportConfigsController, type: :request do
  let(:admin_role) { create(:role, can_view_projects: true, can_edit_data_sources: true, can_manage_config: true) }
  let(:viewer_role) { create(:role, can_view_projects: true) }
  let(:editable_data_source) { create(:source_data_source) }
  let(:view_only_data_source) { create(:source_data_source) }
  let(:viewed_project) { create(:hud_project, data_source: view_only_data_source) }

  def create_config(data_source)
    GrdaWarehouse::HmisImportConfig.create!(
      data_source_id: data_source.id,
      s3_region: 'us-east-1',
      s3_bucket_name: 'original-bucket',
      s3_access_key_id: 'AKIAEXAMPLE',
      s3_secret_access_key: 'SECRET-ACCESS-KEY',
      s3_path: 'hmis/',
      zip_file_password: 'ZIP-PASSWORD',
    )
  end

  before do
    allow_any_instance_of(GrdaWarehouse::HmisImportConfig).to receive(:relevant_object_list).and_return([])
  end

  context 'with admin rights on one data source and project view on another' do
    let(:user) { create(:acl_user) }
    let(:edit_collection) { create(:collection) }
    let(:view_collection) { create(:collection) }
    let!(:editable_config) { create_config(editable_data_source) }
    let!(:view_only_config) { create_config(view_only_data_source) }

    before do
      edit_collection.set_viewables({ data_sources: [editable_data_source.id] })
      view_collection.set_viewables({ projects: [viewed_project.id] })
      setup_access_control(user, admin_role, edit_collection)
      setup_access_control(user, viewer_role, view_collection)
      sign_in user
    end

    it 'does not render the edit page, which shows the S3 credentials and zip password, for the view-only data source' do
      get edit_data_source_hmis_import_config_path(view_only_data_source)
      expect(response).to have_http_status(:not_found)
    end

    it 'does not update the view-only data source config' do
      patch data_source_hmis_import_config_path(view_only_data_source), params: { config: { s3_bucket_name: 'other-bucket' } }
      expect(response).to have_http_status(:not_found)
      expect(view_only_config.reload.s3_bucket_name).to eq('original-bucket')
    end

    it 'does not download files from the view-only data source bucket' do
      expect_any_instance_of(GrdaWarehouse::HmisImportConfig).not_to receive(:s3)
      get download_data_source_hmis_import_config_path(view_only_data_source, key: 'hmis/export.zip')
      expect(response).to have_http_status(:not_found)
    end

    it 'still edits and updates the config on the data source the role covers' do
      get edit_data_source_hmis_import_config_path(editable_data_source)
      expect(response).to have_http_status(:ok)

      patch data_source_hmis_import_config_path(editable_data_source), params: { config: { s3_bucket_name: 'other-bucket' } }
      expect(editable_config.reload.s3_bucket_name).to eq('other-bucket')
    end
  end
end
