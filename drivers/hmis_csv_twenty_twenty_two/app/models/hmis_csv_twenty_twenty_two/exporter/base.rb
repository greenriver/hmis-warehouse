###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
require 'csv'
module HmisCsvTwentyTwentyTwo::Exporter
  class Base
    include ArelHelper
    include ::Export::Exporter
    include ::Export::Scopes

    attr_accessor :logger, :notifier_config, :file_path, :version, :export

    def initialize( # rubocop:disable  Metrics/ParameterLists
      version: '2022',
      user_id:,
      start_date:,
      end_date:,
      projects:,
      period_type: nil,
      directive: nil,
      hash_status: nil,
      faked_pii: false,
      include_deleted: false,
      faked_environment: :development,
      file_path: 'var/hmis_export',
      logger: Rails.logger,
      debug: true
    )
      setup_notifier('HMIS Exporter 2022')
      @version = version
      @file_path = "#{file_path}/#{Time.now.to_f}"
      @logger = logger
      @debug = debug
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
      @projects = projects
      @period_type = period_type.presence || 3
      @directive = directive.presence || 2
      @hash_status = hash_status.presence || 1
      @faked_pii = faked_pii
      @user = ::User.find(user_id)
      @include_deleted = include_deleted
      @faked_environment = faked_environment
    end

    def export!
      create_export_directory
      begin
        set_time_format
        setup_export

        # Project related items
        export_projects
        export_project_cocs
        export_organizations
        export_inventories
        export_funders
        export_affiliations

        # Enrollment related
        export_enrollments
        export_exits
        export_clients
        export_enrollment_cocs
        export_disabilities
        export_employment_educations
        export_health_and_dvs
        export_income_benefits
        export_services
        export_current_living_situations
        export_assessments
        export_assessment_questions
        export_assessment_results
        export_events
        export_youth_education_statuses

        export_users

        build_export_file
        zip_archive
        upload_zip
        save_fake_data
      ensure
        remove_export_files
        reset_time_format
      end
      @export
    end

    def export_projects
      project_source.new.export!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_project_cocs
      project_coc_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_organizations
      organization_source.new.export!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_inventories
      inventory_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_funders
      funder_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_affiliations
      affiliation_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_enrollments
      enrollment_source.new.export!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_enrollment_cocs
      enrollment_coc_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_clients
      client_source.new.export!(
        client_scope: client_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_disabilities
      disability_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_employment_educations
      employment_education_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_exits
      exit_source.new.export!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_health_and_dvs
      health_and_dv_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_income_benefits
      income_benefits_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_services
      service_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_current_living_situations
      current_living_situation_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_assessments
      assessment_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_assessment_questions
      assessment_question_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_assessment_results
      assessment_result_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_events
      event_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_youth_education_statuses
      youth_education_status_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def export_users
      user_source.new.export!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
      )
    end

    def build_export_file
      export = export_source.new(path: @file_path)
      export.ExportID = @export.export_id
      export.SourceType = 3 # data warehouse
      export.SourceID = _('Boston DND Warehouse')[0..31] # potentially more than one CoC
      export.SourceName = _('Boston DND Warehouse')
      export.SourceContactFirst = @user&.first_name || 'Automated'
      export.SourceContactLast = @user&.last_name || 'Export'
      export.SourceContactEmail = @user&.email
      export.ExportDate = Date.current
      export.ExportStartDate = @range.start
      export.ExportEndDate = @range.end
      export.SoftwareName = _('OpenPath HMIS Warehouse')
      export.SoftwareVersion = 1
      export.CSVVersion = '2022'
      export.ExportPeriodType = @period_type
      export.ExportDirective = @directive || 2
      export.HashStatus = @hash_status
      export.export!
    end

    def exportable_files
      self.class.exportable_files
    end

    def self.exportable_files
      {
        'Affiliation.csv' => affiliation_source,
        'Client.csv' => client_source,
        'Disabilities.csv' => disability_source,
        'EmploymentEducation.csv' => employment_education_source,
        'Enrollment.csv' => enrollment_source,
        'EnrollmentCoC.csv' => enrollment_coc_source,
        'Exit.csv' => exit_source,
        'Export.csv' => export_source,
        'Funder.csv' => funder_source,
        'HealthAndDV.csv' => health_and_dv_source,
        'IncomeBenefits.csv' => income_benefits_source,
        'Inventory.csv' => inventory_source,
        'Organization.csv' => organization_source,
        'Project.csv' => project_source,
        'ProjectCoC.csv' => project_coc_source,
        'Services.csv' => service_source,
        'CurrentLivingSituation.csv' => current_living_situation_source,
        'Assessment.csv' => assessment_source,
        'AssessmentQuestions.csv' => assessment_question_source,
        'AssessmentResults.csv' => assessment_result_source,
        'Event.csv' => event_source,
        'User.csv' => user_source,
        'YouthEducationStatus.csv' => youth_education_status_source,
      }.freeze
    end

    def self.affiliation_source
      HmisCsvTwentyTwentyTwo::Exporter::Affiliation
    end

    def affiliation_source
      self.class.affiliation_source
    end

    def self.client_source
      HmisCsvTwentyTwentyTwo::Exporter::Client
    end

    def client_source
      self.class.client_source
    end

    def self.disability_source
      HmisCsvTwentyTwentyTwo::Exporter::Disability
    end

    def disability_source
      self.class.disability_source
    end

    def self.employment_education_source
      HmisCsvTwentyTwentyTwo::Exporter::EmploymentEducation
    end

    def employment_education_source
      self.class.employment_education_source
    end

    def self.enrollment_source
      HmisCsvTwentyTwentyTwo::Exporter::Enrollment
    end

    def enrollment_source
      self.class.enrollment_source
    end

    def self.enrollment_coc_source
      HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc
    end

    def enrollment_coc_source
      self.class.enrollment_coc_source
    end

    def self.exit_source
      HmisCsvTwentyTwentyTwo::Exporter::Exit
    end

    def exit_source
      self.class.exit_source
    end

    def self.export_source
      HmisCsvTwentyTwentyTwo::Exporter::Export
    end

    def export_source
      self.class.export_source
    end

    def self.funder_source
      HmisCsvTwentyTwentyTwo::Exporter::Funder
    end

    def funder_source
      self.class.funder_source
    end

    def self.health_and_dv_source
      HmisCsvTwentyTwentyTwo::Exporter::HealthAndDv
    end

    def health_and_dv_source
      self.class.health_and_dv_source
    end

    def self.income_benefits_source
      HmisCsvTwentyTwentyTwo::Exporter::IncomeBenefit
    end

    def income_benefits_source
      self.class.income_benefits_source
    end

    def self.inventory_source
      HmisCsvTwentyTwentyTwo::Exporter::Inventory
    end

    def inventory_source
      self.class.inventory_source
    end

    def self.organization_source
      HmisCsvTwentyTwentyTwo::Exporter::Organization
    end

    def organization_source
      self.class.organization_source
    end

    def self.project_source
      HmisCsvTwentyTwentyTwo::Exporter::Project
    end

    def project_source
      self.class.project_source
    end

    def self.project_coc_source
      HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc
    end

    def project_coc_source
      self.class.project_coc_source
    end

    def self.service_source
      HmisCsvTwentyTwentyTwo::Exporter::Service
    end

    def service_source
      self.class.service_source
    end

    def self.current_living_situation_source
      HmisCsvTwentyTwentyTwo::Exporter::CurrentLivingSituation
    end

    def current_living_situation_source
      self.class.current_living_situation_source
    end

    def self.assessment_source
      HmisCsvTwentyTwentyTwo::Exporter::Assessment
    end

    def assessment_source
      self.class.assessment_source
    end

    def self.assessment_question_source
      HmisCsvTwentyTwentyTwo::Exporter::AssessmentQuestion
    end

    def assessment_question_source
      self.class.assessment_question_source
    end

    def self.assessment_result_source
      HmisCsvTwentyTwentyTwo::Exporter::AssessmentResult
    end

    def assessment_result_source
      self.class.assessment_result_source
    end

    def self.event_source
      HmisCsvTwentyTwentyTwo::Exporter::Event
    end

    def event_source
      self.class.event_source
    end

    def self.youth_education_status_source
      HmisCsvTwentyTwentyTwo::Exporter::YouthEducationStatus
    end

    def youth_education_status_source
      self.class.youth_education_status_source
    end

    def self.user_source
      HmisCsvTwentyTwentyTwo::Exporter::User
    end

    def user_source
      self.class.user_source
    end
  end
end
