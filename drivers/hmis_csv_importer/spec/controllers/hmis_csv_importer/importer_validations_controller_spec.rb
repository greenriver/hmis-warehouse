# frozen_string_literal: true

require 'rails_helper'
require 'roo'
require_relative './shared_importer_controller_context'

RSpec.describe HmisCsvImporter::ImporterValidationsController, type: :controller do
  render_views
  include_context 'shared importer controller'

  let!(:validation) { create(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id) }
  let!(:validation_with_minimal_source) do
    create(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end

  describe 'GET #download' do
    it 'generates xlsx file' do
      get :download, params: { id: importer_log.id, file: 'Enrollment' }, format: :xlsx
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include('Enrollment_errors.xlsx')
      expect(response.content_type).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    it 'handles nil sources without crashing' do
      create_invalid_source_record(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id)

      get :download, params: { id: importer_log.id, file: 'Enrollment' }, format: :xlsx
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include('Enrollment_errors.xlsx')
      expect(response.content_type).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

      require 'tempfile'
      temp_file = Tempfile.new(['test', '.xlsx'])
      temp_file.binmode
      temp_file.write(response.body)
      temp_file.rewind

      xlsx = Roo::Excelx.new(temp_file.path)
      validation_sheet = xlsx.sheet('Enrollment.csv Validation Flags')
      expect(validation_sheet.row(1)[0]).to eq('Message')

      temp_file.close
      temp_file.unlink
    end
  end

  describe 'GET #show' do
    it 'paginates validations' do
      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(assigns(:validations)).to include(validation)
      expect(assigns(:validations)).to include(validation_with_minimal_source)
    end

    it 'handles nil sources without crashing' do
      create_invalid_source_record(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id)

      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(response).to have_http_status(:success)
      expect(assigns(:validations)).to be_present
    end
  end
end
