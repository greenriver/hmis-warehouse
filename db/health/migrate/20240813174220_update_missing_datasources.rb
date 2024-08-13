class UpdateMissingDatasources < ActiveRecord::Migration[7.0]
  def change
    data_source_id = Health::Patient.first_or_initialize.data_source_id
    HealthThriveAssessment::Assessment.update_all(data_source_id: data_source_id)
    Health::EpicHousingStatus.update_all(data_source_id: data_source_id)
  end
end
