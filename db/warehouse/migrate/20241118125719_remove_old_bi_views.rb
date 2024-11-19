class RemoveOldBiViews < ActiveRecord::Migration[7.0]
  def up
    [
      'DROP VIEW IF EXISTS "bi_Services"',
      'DROP VIEW IF EXISTS "bi_Exit"',
      'DROP VIEW IF EXISTS "bi_EnrollmentCoC"',
      'DROP VIEW IF EXISTS "bi_Disabilities"',
      'DROP VIEW IF EXISTS "bi_HealthAndDV"',
      'DROP VIEW IF EXISTS "bi_IncomeBenefits"',
      'DROP VIEW IF EXISTS "bi_EmploymentEducation"',
      'DROP VIEW IF EXISTS "bi_CurrentLivingSituation"',
      'DROP VIEW IF EXISTS "bi_Event"',
      'DROP VIEW IF EXISTS "bi_Assessment"',
      'DROP VIEW IF EXISTS "bi_AssessmentQuestions"',
      'DROP VIEW IF EXISTS "bi_AssessmentResults"',
      'DROP VIEW IF EXISTS "bi_Enrollment"',
      'DROP VIEW IF EXISTS "bi_Client"',
      'DROP VIEW IF EXISTS "bi_Demographics"',
      'DROP VIEW IF EXISTS "bi_Funder"',
      'DROP VIEW IF EXISTS "bi_Inventory"',
      'DROP VIEW IF EXISTS "bi_Export"',
      'DROP VIEW IF EXISTS "bi_Affiliation"',
      'DROP VIEW IF EXISTS "bi_ProjectCoC"',
      'DROP VIEW IF EXISTS "bi_Project"',
      'DROP VIEW IF EXISTS "bi_Organization"',
      'DROP VIEW IF EXISTS "bi_service_history_enrollments"',
      'DROP VIEW IF EXISTS "bi_service_history_services"',
      'DROP VIEW IF EXISTS "bi_data_sources"',
      'DROP VIEW IF EXISTS "bi_lookups_funding_sources"',
      'DROP VIEW IF EXISTS "bi_lookups_genders"',
      'DROP VIEW IF EXISTS "bi_lookups_living_situations"',
      'DROP VIEW IF EXISTS "bi_lookups_project_types"',
      'DROP VIEW IF EXISTS "bi_lookups_relationships"',
      'DROP VIEW IF EXISTS "bi_lookups_tracking_methods"',
      'DROP VIEW IF EXISTS "bi_lookups_yes_no_etcs"',
      'DROP VIEW IF EXISTS "bi_nightly_census_by_projects"',
    ].each do |sql|
      GrdaWarehouseBase.connection.execute(sql)
    end
  end
end
