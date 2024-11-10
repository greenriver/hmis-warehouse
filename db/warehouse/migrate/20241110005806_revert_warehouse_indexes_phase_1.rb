
# The 20241010005805_prune_warehouse_indexes_phase_1 ran on staging and removed some indexes that
# proved to be in use.
class RevertWarehouseIndexesPhase1< ActiveRecord::Migration[7.0]
  def up
    # the migration in question (we are reverting) only ran on staging/dev so skip if this is prod
    return if Rails.env.production?

    connection = GrdaWarehouseBase.connection
    indexes.each do |sql|
      connection.execute(sql)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  protected

  def indexes
    <<~TEXT
      CREATE INDEX IF NOT EXISTS "hmis_2022_affiliations-6457" ON public.hmis_2022_affiliations USING btree ("AffiliationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_2022_funders-4ad5" ON public.hmis_2022_funders USING btree ("FunderID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_2022_organizations-7580" ON public.hmis_2022_organizations USING btree ("OrganizationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_2024_users-b749" ON public.hmis_2024_users USING btree ("UserID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_affiliations-6457" ON public.hmis_csv_2022_affiliations USING btree ("AffiliationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_current_living_situations-cf31" ON public.hmis_csv_2022_current_living_situations USING btree ("CurrentLivingSitID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_funders-4ad5" ON public.hmis_csv_2022_funders USING btree ("FunderID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_health_and_dvs-e384" ON public.hmis_csv_2022_health_and_dvs USING btree ("HealthAndDVID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_inventories-86c0" ON public.hmis_csv_2022_inventories USING btree ("InventoryID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_organizations-7580" ON public.hmis_csv_2022_organizations USING btree ("OrganizationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_project_cocs-3966" ON public.hmis_csv_2022_project_cocs USING btree ("ProjectCoCID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_projects-92c5" ON public.hmis_csv_2022_projects USING btree ("ProjectID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2022_services-7a57" ON public.hmis_csv_2022_services USING btree ("ServicesID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_affiliations-6457" ON public.hmis_csv_2024_affiliations USING btree ("AffiliationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_assessment_questions-0cd3" ON public.hmis_csv_2024_assessment_questions USING btree ("AssessmentQuestionID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_current_living_situations-cf31" ON public.hmis_csv_2024_current_living_situations USING btree ("CurrentLivingSitID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_disabilities-7712" ON public.hmis_csv_2024_disabilities USING btree ("DisabilitiesID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_employment_educations-3032" ON public.hmis_csv_2024_employment_educations USING btree ("EmploymentEducationID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_funders-4ad5" ON public.hmis_csv_2024_funders USING btree ("FunderID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_health_and_dvs-e384" ON public.hmis_csv_2024_health_and_dvs USING btree ("HealthAndDVID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_services-7a57" ON public.hmis_csv_2024_services USING btree ("ServicesID", data_source_id)
      CREATE INDEX IF NOT EXISTS "hmis_csv_2024_youth_education_statuses-a32f" ON public.hmis_csv_2024_youth_education_statuses USING btree ("YouthEducationStatusID", data_source_id)
      CREATE INDEX IF NOT EXISTS hmis2022enrollmentcocs_e294 ON public.hmis_2022_enrollment_cocs USING btree ("CoCCode")
      CREATE INDEX IF NOT EXISTS hmis2022enrollments_3328 ON public.hmis_2022_enrollments USING btree ("RelationshipToHoH")
      CREATE INDEX IF NOT EXISTS hmis2022enrollments_c548 ON public.hmis_2022_enrollments USING btree ("EnrollmentID", "PersonalID")
      CREATE INDEX IF NOT EXISTS hmis2022exits_fa9a ON public.hmis_2022_exits USING btree ("ExitDate")
      CREATE INDEX IF NOT EXISTS hmis2022incomebenefits_634d ON public.hmis_2022_income_benefits USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2022incomebenefits_ae8d ON public.hmis_2022_income_benefits USING btree ("IncomeFromAnySource", "DataCollectionStage")
      CREATE INDEX IF NOT EXISTS hmis2022inventories_9529 ON public.hmis_2022_inventories USING btree ("InventoryID")
      CREATE INDEX IF NOT EXISTS hmis2022services_c548 ON public.hmis_2022_services USING btree ("EnrollmentID", "PersonalID")
      CREATE INDEX IF NOT EXISTS hmis2022users_57c7 ON public.hmis_2022_users USING btree ("UserID")
      CREATE INDEX IF NOT EXISTS hmis2022youtheducationstatuses_fabe ON public.hmis_2022_youth_education_statuses USING btree ("InformationDate")
      CREATE INDEX IF NOT EXISTS hmis2024assessmentquestions_da04 ON public.hmis_2024_assessment_questions USING btree ("AssessmentID")
      CREATE INDEX IF NOT EXISTS hmis2024ceparticipations_42af ON public.hmis_2024_ce_participations USING btree ("ProjectID")
      CREATE INDEX IF NOT EXISTS hmis2024clients_634d ON public.hmis_2024_clients USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024disabilities_d381 ON public.hmis_2024_disabilities USING btree ("DateCreated")
      CREATE INDEX IF NOT EXISTS hmis2024enrollments_3085 ON public.hmis_2024_enrollments USING btree ("PreviousStreetESSH", "LengthOfStay")
      CREATE INDEX IF NOT EXISTS hmis2024enrollments_634d ON public.hmis_2024_enrollments USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024exits_634d ON public.hmis_2024_exits USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024funders_d381 ON public.hmis_2024_funders USING btree ("DateCreated")
      CREATE INDEX IF NOT EXISTS hmis2024hmisparticipations_42af ON public.hmis_2024_hmis_participations USING btree ("ProjectID")
      CREATE INDEX IF NOT EXISTS hmis2024incomebenefits_634d ON public.hmis_2024_income_benefits USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024inventories_d381 ON public.hmis_2024_inventories USING btree ("DateCreated")
      CREATE INDEX IF NOT EXISTS hmis2024organizations_634d ON public.hmis_2024_organizations USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024services_634d ON public.hmis_2024_services USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmis2024users_57c7 ON public.hmis_2024_users USING btree ("UserID")
      CREATE INDEX IF NOT EXISTS hmiscsv2022clients_603f ON public.hmis_csv_2022_clients USING btree ("PersonalID")
      CREATE INDEX IF NOT EXISTS hmiscsv2022enrollmentcocs_f3a2 ON public.hmis_csv_2022_enrollment_cocs USING btree ("DateDeleted")
      CREATE INDEX IF NOT EXISTS hmiscsv2022enrollments_3085 ON public.hmis_csv_2022_enrollments USING btree ("PreviousStreetESSH", "LengthOfStay")
      CREATE INDEX IF NOT EXISTS hmiscsv2022incomebenefits_16c2 ON public.hmis_csv_2022_income_benefits USING btree ("Earned", "DataCollectionStage")
      CREATE INDEX IF NOT EXISTS hmiscsv2022incomebenefits_ae8d ON public.hmis_csv_2022_income_benefits USING btree ("IncomeFromAnySource", "DataCollectionStage")
      CREATE INDEX IF NOT EXISTS hmiscsv2022inventories_9529 ON public.hmis_csv_2022_inventories USING btree ("InventoryID")
      CREATE INDEX IF NOT EXISTS hmiscsv2022users_57c7 ON public.hmis_csv_2022_users USING btree ("UserID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024assessmentquestions_da04 ON public.hmis_csv_2024_assessment_questions USING btree ("AssessmentID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024assessments_4fa0 ON public.hmis_csv_2024_assessments USING btree ("AssessmentDate")
      CREATE INDEX IF NOT EXISTS hmiscsv2024ceparticipations_42af ON public.hmis_csv_2024_ce_participations USING btree ("ProjectID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024ceparticipations_5a29 ON public.hmis_csv_2024_ce_participations USING btree ("CEParticipationID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024ceparticipations_634d ON public.hmis_csv_2024_ce_participations USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024currentlivingsituations_c1ef ON public.hmis_csv_2024_current_living_situations USING btree ("CurrentLivingSitID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024disabilities_1873 ON public.hmis_csv_2024_disabilities USING btree ("DisabilitiesID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024employmenteducations_350e ON public.hmis_csv_2024_employment_educations USING btree ("EmploymentEducationID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024events_5251 ON public.hmis_csv_2024_events USING btree ("EventID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024events_ab19 ON public.hmis_csv_2024_events USING btree ("EventDate")
      CREATE INDEX IF NOT EXISTS hmiscsv2024exits_42d5 ON public.hmis_csv_2024_exits USING btree ("DateUpdated")
      CREATE INDEX IF NOT EXISTS hmiscsv2024exits_fa9a ON public.hmis_csv_2024_exits USING btree ("ExitDate")
      CREATE INDEX IF NOT EXISTS hmiscsv2024healthanddvs_1329 ON public.hmis_csv_2024_health_and_dvs USING btree ("HealthAndDVID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024hmisparticipations_42af ON public.hmis_csv_2024_hmis_participations USING btree ("ProjectID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024hmisparticipations_634d ON public.hmis_csv_2024_hmis_participations USING btree ("ExportID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024projectcocs_787b ON public.hmis_csv_2024_project_cocs USING btree ("ProjectCoCID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024services_3444 ON public.hmis_csv_2024_services USING btree ("DateProvided")
      CREATE INDEX IF NOT EXISTS hmiscsv2024users_57c7 ON public.hmis_csv_2024_users USING btree ("UserID")
      CREATE INDEX IF NOT EXISTS hmiscsv2024youtheducationstatuses_fabe ON public.hmis_csv_2024_youth_education_statuses USING btree ("InformationDate")
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_clients_on_loader_id ON public.hmis_csv_2020_clients USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_current_living_situations_on_loader_id ON public.hmis_csv_2020_current_living_situations USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_enrollment_cocs_on_loader_id ON public.hmis_csv_2020_enrollment_cocs USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_enrollments_on_loader_id ON public.hmis_csv_2020_enrollments USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_exports_on_loader_id ON public.hmis_csv_2020_exports USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_project_cocs_on_loader_id ON public.hmis_csv_2020_project_cocs USING btree (loader_id)
      CREATE INDEX IF NOT EXISTS index_hmis_csv_2020_services_on_loader_id ON public.hmis_csv_2020_services USING btree (loader_id)
    TEXT
  end
end
