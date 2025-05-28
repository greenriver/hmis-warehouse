# frozen_string_literal: true

RSpec.shared_context 'shared importer controller' do
  let!(:user) { create :acl_user }
  let!(:role) { create :admin_role, can_view_imports: true }
  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
  let!(:minimal_source) do
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
  let!(:import_log) { create(:grda_warehouse_import_log, importer_log_id: importer_log.id, data_source: data_source) }
  let!(:validation) { create(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id) }
  let!(:error) { create(:hmis_csv_import_error, importer_log_id: importer_log.id) }
  let!(:validation_with_minimal_source) do
    create(:hmis_csv_import_inclusion_validation, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end
  let!(:error_with_minimal_source) do
    create(:hmis_csv_import_error, importer_log_id: importer_log.id, source_id: minimal_source.id, source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment')
  end

  before do
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    sign_in(user)
  end

  def create_invalid_source_record(klass, importer_log_id:)
    create(
      klass,
      importer_log_id: importer_log_id,
      source_id: -1,
      source_type: 'HmisCsvTwentyTwentyFour::Loader::Enrollment',
    )
  end
end
