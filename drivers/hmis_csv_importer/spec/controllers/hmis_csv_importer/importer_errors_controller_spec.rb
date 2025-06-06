# frozen_string_literal: true

require 'rails_helper'
require 'roo'
require_relative './shared_importer_controller_context'

RSpec.describe HmisCsvImporter::ImporterErrorsController, type: :controller do
  render_views
  include_context 'shared importer controller'

  describe 'GET #download' do
    it 'generates xlsx file' do
      get :download, params: { id: importer_log.id }, format: :xlsx
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include("import_errors_#{importer_log.id}.xlsx")
      expect(response.content_type).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    it 'handles nil sources without crashing' do
      create_invalid_source_record(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id)
      create_invalid_source_record(:hmis_csv_import_error, importer_log_id: importer_log.id)

      get :download, params: { id: importer_log.id }, format: :xlsx
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include("import_errors_#{importer_log.id}.xlsx")
      expect(response.content_type).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

      # Verify Excel was generated with empty arrays for nil sources
      require 'tempfile'
      temp_file = Tempfile.new(['test', '.xlsx'])
      temp_file.binmode
      temp_file.write(response.body)
      temp_file.rewind

      xlsx = Roo::Excelx.new(temp_file.path)

      # Check validation sheet
      validation_sheet = xlsx.sheet('Enrollment Validation Flags')
      expect(validation_sheet.row(1)[0]).to eq('Message')
      expect(validation_sheet.row(2)[0]).to eq('warning')

      # Check error sheet
      error_sheet = xlsx.sheet('Enrollment Error Flags')
      expect(error_sheet.row(1)[0]).to eq('Message')
      expect(error_sheet.row(2)[0]).to eq('Test error details')

      temp_file.close
      temp_file.unlink
    end
  end

  describe 'GET #show' do
    it 'paginates errors' do
      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(assigns(:errors)).to include(error)
      expect(assigns(:errors)).to include(error_with_minimal_source)
    end
  end
end
