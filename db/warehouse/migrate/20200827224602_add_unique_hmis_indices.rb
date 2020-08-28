class AddUniqueHmisIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :CurrentLivingSituation, [:CurrentLivingSitID, :data_source_id], unique: true, name: 'cur_liv_sit_sit_id_ds_id'

    remove_index :Event, [:EventID, :data_source_id] if index_exists?(:Event, [:EventID, :data_source_id])
    add_index :Event, [:EventID, :data_source_id], unique: true, name: 'ev_ev_id_ds_id'
    remove_index :Assessment, [:AssessmentID, :data_source_id] if index_exists?(:Event, [:EventID, :data_source_id])
    add_index :Assessment, [:AssessmentID, :data_source_id], unique: true
    remove_index :AssessmentResults, [:AssessmentResultID, :data_source_id] if index_exists?(:AssessmentResults, [:AssessmentResultID, :data_source_id])
    add_index :AssessmentResults, [:AssessmentResultID, :data_source_id], unique: true, name: 'ar_ar_id_ds_id'
    remove_index :AssessmentQuestions, [:AssessmentQuestionID, :data_source_id] if index_exists?(:AssessmentQuestions, [:AssessmentQuestionID, :data_source_id])
    add_index :AssessmentQuestions, [:AssessmentQuestionID, :data_source_id], unique: true, name: 'aq_aq_id_ds_id'
    remove_index :User, [:UserID, :data_source_id] if index_exists?(:User, [:UserID, :data_source_id])
    add_index :User, [:UserID, :data_source_id], unique: true
    remove_index :Affiliation, [:data_source_id, :AffiliationID] if index_exists?(:Affiliation, [:data_source_id, :AffiliationID])
    add_index :Affiliation, [:AffiliationID, :data_source_id], unique: true
    remove_index :Services, [:data_source_id, :ServicesID] if index_exists?(:Services, [:data_source_id, :ServicesID])
    add_index :Services, [:ServicesID, :data_source_id], unique: true
    remove_index :Enrollment, [:data_source_id, :EnrollmentID, :PersonalID] if index_exists?(:Enrollment, [:data_source_id, :EnrollmentID, :PersonalID])
    add_index :Enrollment, [:EnrollmentID, :PersonalID, :data_source_id], unique: true, name: 'en_en_id_p_id_ds_id'
    remove_index :EnrollmentCoC, [:data_source_id, :EnrollmentCoCID] if index_exists?(:EnrollmentCoC, [:data_source_id, :EnrollmentCoCID])
    add_index :EnrollmentCoC, [:EnrollmentCoCID, :data_source_id], unique: true
    remove_index :Disabilities, [:data_source_id, :DisabilitiesID] if index_exists?(:Disabilities, [:data_source_id, :DisabilitiesID])
    add_index :Disabilities, [:DisabilitiesID, :data_source_id], unique: true
    remove_index :HealthAndDV, [:data_source_id, :HealthAndDVID] if index_exists?(:HealthAndDV, [:data_source_id, :HealthAndDVID])
    add_index :HealthAndDV, [:HealthAndDVID, :data_source_id], unique: true
    remove_index :Inventory, [:data_source_id, :InventoryID] if index_exists?(:Inventory, [:data_source_id, :InventoryID])
    add_index :Inventory, [:InventoryID, :data_source_id], unique: true
    remove_index :IncomeBenefits, [:data_source_id, :IncomeBenefitsID] if index_exists?(:IncomeBenefits, [:data_source_id, :IncomeBenefitsID])
    add_index :IncomeBenefits, [:IncomeBenefitsID, :data_source_id], unique: true
    remove_index :EmploymentEducation, [:data_source_id, :EmploymentEducationID] if index_exists?(:EmploymentEducation, [:data_source_id, :EmploymentEducationID])
    add_index :EmploymentEducation, [:EmploymentEducationID, :data_source_id], unique: true, name: 'ee_ee_id_ds_id'
    remove_index :Exit, [:data_source_id, :ExitID] if index_exists?(:Exit, [:data_source_id, :ExitID])
    add_index :Exit, [:ExitID, :data_source_id], unique: true
    remove_index :Export, [:data_source_id, :ExportID] if index_exists?(:Export, [:data_source_id, :ExportID])
    add_index :Export, [:ExportID, :data_source_id], unique: true
    remove_index :Funder, [:data_source_id, :FunderID] if index_exists?(:Funder, [:data_source_id, :FunderID])
    add_index :Funder, [:FunderID, :data_source_id], unique: true
    remove_index :ProjectCoC, [:data_source_id, :ProjectCoCID] if index_exists?(:ProjectCoC, [:data_source_id, :ProjectCoCID])
    add_index :ProjectCoC, [:ProjectCoCID, :data_source_id], unique: true
  end
end
