# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_importer_controller_context'

RSpec.describe HmisCsvImporter::ImporterValidationErrorsController, type: :controller do
  render_views
  include_context 'shared importer controller'

  let!(:validation) { create(:hmis_csv_import_length_validation, importer_log_id: importer_log.id) }
  let!(:validation_with_minimal_source) do
    create(:hmis_csv_import_length_validation, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end

  describe 'GET #show' do
    it 'paginates validations' do
      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(assigns(:validations)).to include(validation)
      expect(assigns(:validations)).to include(validation_with_minimal_source)
    end

    it 'handles nil sources without crashing' do
      create_invalid_source_record(:hmis_csv_import_length_validation, importer_log_id: importer_log.id)

      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(response).to have_http_status(:success)
      expect(assigns(:validations)).to be_present
    end
  end
end
