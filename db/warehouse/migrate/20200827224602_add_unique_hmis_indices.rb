class AddUniqueHmisIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :Event, [:EventID, :data_source_id], unique: true
    # add_index :Client, [:PersonalID, :data_source_id], unique: true, where: '("DateDeleted" IS NULL)'
    add_index :CurrentLivingSituation, [:CurrentLivingSitID, :data_source_id], unique: true, name: 'cur_liv_sit_sit_id_ds_id', where: '("DateDeleted" IS NULL)'
    remove_index :Assessment, [:AssessmentID, :data_source_id]
    add_index :Assessment, [:AssessmentID, :data_source_id], unique: true
    remove_index :AssessmentResults, [:AssessmentResultID, :data_source_id]
    add_index :AssessmentResults, [:AssessmentResultID, :data_source_id], unique: true, name: 'ar_ar_id_ds_id'
    remove_index :AssessmentQuestions, [:AssessmentQuestionID, :data_source_id]
    add_index :AssessmentQuestions, [:AssessmentQuestionID, :data_source_id], unique: true, name: 'aq_aq_id_ds_id'
    remove_index :User, [:UserID, :data_source_id]
    add_index :User, [:UserID, :data_source_id], unique: true

    remove_index :Affiliation, [:data_source_id, :AffiliationID]
    add_index :Affiliation, [:AffiliationID, :data_source_id], unique: true
    remove_index :Services, [:data_source_id, :ServicesID]
    add_index :Services, [:ServicesID, :data_source_id], unique: true
    remove_index :Enrollment, [:data_source_id, :EnrollmentID, :PersonalID]
    add_index :Enrollment, [:EnrollmentID, :PersonalID, :data_source_id], unique: true, name: 'en_en_id_p_id_ds_id'
    remove_index :EnrollmentCoC, [:data_source_id, :EnrollmentCoCID]
    add_index :EnrollmentCoC, [:EnrollmentCoCID, :data_source_id], unique: true
    remove_index :Disabilities, [:data_source_id, :DisabilitiesID]
    add_index :Disabilities, [:DisabilitiesID, :data_source_id], unique: true
    remove_index :HealthAndDV, [:data_source_id, :HealthAndDVID]
    add_index :HealthAndDV, [:HealthAndDVID, :data_source_id], unique: true
    remove_index :Inventory, [:data_source_id, :InventoryID]
    add_index :Inventory, [:InventoryID, :data_source_id], unique: true
    remove_index :IncomeBenefits, [:data_source_id, :IncomeBenefitsID]
    add_index :IncomeBenefits, [:IncomeBenefitsID, :data_source_id], unique: true
    remove_index :EmploymentEducation, [:data_source_id, :EmploymentEducationID]
    add_index :EmploymentEducation, [:EmploymentEducationID, :data_source_id], unique: true, name: 'ee_ee_id_ds_id'
    remove_index :Exit, [:data_source_id, :ExitID]
    add_index :Exit, [:ExitID, :data_source_id], unique: true
    remove_index :Export, [:data_source_id, :ExportID]
    add_index :Export, [:ExportID, :data_source_id], unique: true
    remove_index :Funder, [:data_source_id, :FunderID]
    add_index :Funder, [:FunderID, :data_source_id], unique: true
    remove_index :ProjectCoC, [:data_source_id, :ProjectCoCID]
    add_index :ProjectCoC, [:ProjectCoCID, :data_source_id], unique: true
  end
end
