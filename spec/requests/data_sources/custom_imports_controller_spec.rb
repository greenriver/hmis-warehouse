###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSources::CustomImportsController, type: :request do
  let(:data_source) { create(:source_data_source) }
  let(:role) { create(:role, can_edit_data_sources: true, can_manage_config: true) }
  let(:user) do
    u = create(:user)
    u.legacy_roles << role
    u
  end
  let(:config) do
    GrdaWarehouse::CustomImports::Config.create!(
      data_source: data_source,
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
    allow(GrdaWarehouse::DataSource).to receive(:viewable_by).with(user).and_return(
      GrdaWarehouse::DataSource.where(id: data_source.id),
    )
    sign_in user
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
