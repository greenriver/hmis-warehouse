class DBA::PartitionAll
  TABLES = %w[
    hmis_2020_affiliations hmis_2020_aggregated_enrollments
    hmis_2020_aggregated_exits hmis_2020_assessment_questions
    hmis_2020_assessment_results hmis_2020_assessments hmis_2020_clients
    hmis_2020_current_living_situations hmis_2020_disabilities
    hmis_2020_employment_educations hmis_2020_enrollment_cocs
    hmis_2020_enrollments hmis_2020_events hmis_2020_exits hmis_2020_exports
    hmis_2020_funders hmis_2020_health_and_dvs hmis_2020_income_benefits
    hmis_2020_inventories hmis_2020_organizations hmis_2020_project_cocs
    hmis_2020_projects hmis_2020_services hmis_2020_users
    hmis_2022_affiliations hmis_2022_assessment_questions
    hmis_2022_assessment_results hmis_2022_assessments hmis_2022_clients
    hmis_2022_current_living_situations hmis_2022_disabilities
    hmis_2022_employment_educations hmis_2022_enrollment_cocs
    hmis_2022_enrollments hmis_2022_events hmis_2022_exits hmis_2022_exports
    hmis_2022_funders hmis_2022_health_and_dvs hmis_2022_income_benefits
    hmis_2022_inventories hmis_2022_organizations hmis_2022_project_cocs
    hmis_2022_projects hmis_2022_services hmis_2022_users
    hmis_2022_youth_education_statuses hmis_csv_2020_affiliations
    hmis_csv_2020_assessment_questions hmis_csv_2020_assessment_results
    hmis_csv_2020_assessments hmis_csv_2020_clients
    hmis_csv_2020_current_living_situations hmis_csv_2020_disabilities
    hmis_csv_2020_employment_educations hmis_csv_2020_enrollment_cocs
    hmis_csv_2020_enrollments hmis_csv_2020_events hmis_csv_2020_exits
    hmis_csv_2020_exports hmis_csv_2020_funders hmis_csv_2020_health_and_dvs
    hmis_csv_2020_income_benefits hmis_csv_2020_inventories
    hmis_csv_2020_organizations hmis_csv_2020_project_cocs
    hmis_csv_2020_projects hmis_csv_2020_services hmis_csv_2020_users
    hmis_csv_2022_affiliations hmis_csv_2022_assessment_questions
    hmis_csv_2022_assessment_results hmis_csv_2022_assessments
    hmis_csv_2022_clients hmis_csv_2022_current_living_situations
    hmis_csv_2022_disabilities hmis_csv_2022_employment_educations
    hmis_csv_2022_enrollment_cocs hmis_csv_2022_enrollments
    hmis_csv_2022_events hmis_csv_2022_exits hmis_csv_2022_exports
    hmis_csv_2022_funders hmis_csv_2022_health_and_dvs
    hmis_csv_2022_income_benefits hmis_csv_2022_inventories
    hmis_csv_2022_organizations hmis_csv_2022_project_cocs
    hmis_csv_2022_projects hmis_csv_2022_services hmis_csv_2022_users
    hmis_csv_2022_youth_education_statuses
  ]

  # 6716 partitions.
  def run!
    Rails.logger.warn "Making #{71*TABLES.length} partitions"

    TABLES.each do |table|
      Rails.logger.info "==== Partitioning #{table} ===="
      pm = DBA::PartitionMaker.new(table_name: table)
      if pm.no_table?
        Rails.logger.error "Skipping #{table} which couldn't be found"
      elsif pm.done?
        Rails.logger.info "Skipping #{table} which is done"
        next
      else
        pm.run!
      end
    end
  end

  # Use this with great care
  def remove_saved_tables!
    raise 'Aborting. You must set DELETE_THEM=true in your environment' unless ENV['DELETE_THEM'] == 'true'

    TABLES.each do |table|
      GrdaWarehouseBase.connection.execute(<<~SQL)
        DROP TABLE "#{table}_saved"
      SQL
    end
  end
end
