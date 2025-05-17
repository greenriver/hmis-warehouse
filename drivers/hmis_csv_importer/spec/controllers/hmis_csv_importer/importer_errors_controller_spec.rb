# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe HmisCsvImporter::ImporterErrorsController, type: :controller do
  render_views
  let(:user) { create :acl_user }
  let(:role) { create :admin_role, can_view_imports: true }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
  let(:minimal_source) do
    # Create a minimal Loader::Enrollment record for use as a source
    HmisCsvTwentyTwentyFour::Loader::Enrollment.create!(
      EnrollmentID: SecureRandom.uuid,
      PersonalID: SecureRandom.uuid,
      ProjectID: SecureRandom.uuid,
      EntryDate: Date.today,
      HouseholdID: SecureRandom.uuid,
      data_source_id: data_source.id,
      loaded_at: Time.current,
      loader_id: 1,
    )
  end
  let(:validation) { create(:hmis_csv_import_validation, importer_log_id: importer_log.id) }
  let(:error) { create(:hmis_csv_import_error, importer_log_id: importer_log.id) }
  let(:validation_with_minimal_source) do
    create(:hmis_csv_import_validation, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end
  let(:error_with_minimal_source) do
    create(:hmis_csv_import_error, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end

  before do
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    sign_in(user)
  end

  describe 'GET #download' do
    before do
      validation
      error
      validation_with_minimal_source
      error_with_minimal_source
    end

    it 'generates xlsx file' do
      get :download, params: { id: importer_log.id }, format: :xlsx
      expect(response.headers['Content-Disposition']).to include("import_errors_#{importer_log.id}.xlsx")
      expect(response.content_type).to include('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

    it 'handles minimal source data' do
      get :download, params: { id: importer_log.id }, format: :xlsx
      expect(response).to have_http_status(:success)
    end

    it 'handles nil sources without crashing' do
      # Create validations and errors with invalid source references
      create(:hmis_csv_import_validation,
             importer_log_id: importer_log.id,
             source_id: -1,
             source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment',
             status: 'Test Status')
      create(:hmis_csv_import_error,
             importer_log_id: importer_log.id,
             source_id: -1,
             source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment',
             details: 'Test Error')

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
    let(:import_log) { create(:grda_warehouse_import_log, importer_log_id: importer_log.id, data_source: data_source) }

    before do
      import_log
      error
      error_with_minimal_source
    end

    it 'paginates errors' do
      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(assigns(:errors)).to include(error)
      expect(assigns(:errors)).to include(error_with_minimal_source)
    end
  end
end
