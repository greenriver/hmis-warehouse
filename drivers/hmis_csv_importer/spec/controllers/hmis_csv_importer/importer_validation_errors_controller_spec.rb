# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_importer_controller_context'

RSpec.describe HmisCsvImporter::ImporterValidationErrorsController, type: :controller do
  render_views
  include_context 'shared importer controller'

  let(:user) { create :acl_user }
  let(:role) { create :admin_role, can_view_imports: true }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
  let(:minimal_source) do
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
  let(:validation_with_minimal_source) do
    create(:hmis_csv_import_validation, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end

  before do
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    sign_in(user)
  end

  describe 'GET #show' do
    let(:import_log) { create(:grda_warehouse_import_log, importer_log_id: importer_log.id, data_source: data_source) }

    before do
      import_log
      validation
      validation_with_minimal_source
    end

    it 'paginates validations' do
      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(assigns(:validations)).to include(validation)
      expect(assigns(:validations)).to include(validation_with_minimal_source)
    end

    it 'handles nil sources without crashing' do
      create_invalid_source_record(:hmis_csv_import_validation, importer_log_id: importer_log.id)

      get :show, params: { id: importer_log.id, file: 'Enrollment' }
      expect(response).to have_http_status(:success)
      expect(assigns(:validations)).to be_present
    end
  end
end
