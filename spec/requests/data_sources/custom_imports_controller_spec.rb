###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSources::CustomImportsController, type: :request do
  let(:data_source) { create(:source_data_source) }
  let(:role) { create(:role, can_view_projects: true, can_edit_data_sources: true, can_manage_config: true) }
  let(:user) { create(:acl_user) }
  let(:collection) { create(:collection) }
  let(:config) { create_config(data_source) }

  def create_config(for_data_source)
    GrdaWarehouse::CustomImports::Config.create!(
      data_source: for_data_source,
      user: user,
      import_type: 'CustomImportsBostonService::ImportFile',
      description: 'Test Import',
      s3_bucket: 'test-bucket',
      s3_prefix: 'prefix/',
      s3_region: 'us-east-1',
      s3_access_key_id: 'unknown',
      s3_secret_access_key: 'unknown',
      import_hour: 4,
      active: true,
    )
  end

  before do
    collection.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'a data source the user can only view through one project' do
    let(:viewer_role) { create(:role, can_view_projects: true) }
    let(:view_collection) { create(:collection) }
    let(:view_only_data_source) { create(:source_data_source) }
    let(:viewed_project) { create(:hud_project, data_source: view_only_data_source) }
    let!(:view_only_config) { create_config(view_only_data_source) }

    before do
      view_collection.set_viewables({ projects: [viewed_project.id] })
      setup_access_control(user, viewer_role, view_collection)
    end

    it 'does not update its custom import config' do
      patch data_source_custom_import_path(view_only_data_source, view_only_config), params: { config: { description: 'Changed' } }
      expect(response).to have_http_status(:not_found)
      expect(view_only_config.reload.description).to eq('Test Import')
    end

    it 'does not delete its custom import config' do
      delete data_source_custom_import_path(view_only_data_source, view_only_config)
      expect(response).to have_http_status(:not_found)
      expect(GrdaWarehouse::CustomImports::Config.exists?(view_only_config.id)).to be(true)
    end

    it 'still updates a config on the data source the role covers' do
      patch data_source_custom_import_path(data_source, config), params: { config: { description: 'Changed' } }
      expect(config.reload.description).to eq('Changed')
    end
  end

  describe 'GET download' do
    let(:s3_double) { instance_double(AwsS3) }
    let(:s3_object) { double(key: 'prefix/test.csv') }

    before do
      allow(config).to receive(:s3).and_return(s3_double)
      allow_any_instance_of(GrdaWarehouse::CustomImports::Config).to receive(:s3).and_return(s3_double)
    end

    context 'when the file exists on S3' do
      before do
        allow(s3_double).to receive(:list_objects).with(prefix: config.s3_path).and_return([s3_object])
        allow(s3_double).to receive(:get_as_io).with(key: 'prefix/test.csv').and_return(StringIO.new('col1,col2\nval1,val2'))
        allow(s3_double).to receive(:get_file_type).with(key: 'prefix/test.csv').and_return('text/csv')
      end

      it 'sends the file' do
        get download_data_source_custom_import_path(data_source, config, key: 'prefix/test.csv')
        expect(response).to be_successful
        expect(response.headers['Content-Disposition']).to include('test.csv')
      end
    end

    context 'when the file is not found on S3' do
      before do
        allow(s3_double).to receive(:list_objects).with(prefix: config.s3_path).and_return([])
      end

      it 'redirects to edit with an error flash' do
        get download_data_source_custom_import_path(data_source, config, key: 'prefix/missing.csv')
        expect(response).to redirect_to(edit_data_source_custom_import_path(data_source, config))
        expect(flash[:error]).to eq('File not found')
      end
    end
  end
end
