###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::LoaderErrorsController, type: :request do
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:loader_log) { HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, summary: { 'Enrollment.csv' => {} }) }
  let!(:import_log) { create(:grda_warehouse_import_log, data_source: data_source, loader_log_id: loader_log.id) }
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:admin_role, can_view_imports: true) }
  let!(:collection) { create(:collection) }

  before do
    collection.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  describe 'GET show' do
    it 'shows only the errors for the requested file' do
      matching = loader_log.load_errors.create!(file_name: 'Enrollment.csv', message: 'Error in Enrollment.csv', details: 'Too many columns found', source: 'E-1,C-1,ES')
      loader_log.load_errors.create!(file_name: 'Exit.csv', message: 'Error in Exit.csv', details: 'Too few columns found', source: 'E-1,2020-01-01')

      get hmis_csv_importer_loader_error_path(loader_log, file: 'Enrollment.csv')

      expect(response.body).to include(matching.details)
      expect(response.body).not_to include('Too few columns found')
    end

    it 'denies access to errors for a loader log belonging to a data source the user cannot view' do
      other_data_source = create(:grda_warehouse_data_source)
      other_loader_log = HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: other_data_source.id, status: :loaded, summary: { 'Enrollment.csv' => {} })
      create(:grda_warehouse_import_log, data_source: other_data_source, loader_log_id: other_loader_log.id)
      other_loader_log.load_errors.create!(file_name: 'Enrollment.csv', message: 'Error in Enrollment.csv', details: 'Too many columns found', source: 'E-9,C-SECRET,ES')

      get hmis_csv_importer_loader_error_path(other_loader_log, file: 'Enrollment.csv')

      expect(response).to have_http_status(:not_found)
    end
  end
end
