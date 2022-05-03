###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
require 'csv'
require 'kiba-common/sources/enumerable'

# Testing notes
# reload!; rh = GrdaWarehouse::RecurringHmisExport.last; rh.run

module HmisCsvTwentyTwentyTwo::Exporter
  class Base
    include ArelHelper
    include ::Export::Exporter
    include ::Export::Scopes

    attr_accessor :logger, :notifier_config, :file_path, :version, :export, :include_deleted

    def initialize( # rubocop:disable  Metrics/ParameterLists
      version: '2022',
      user_id:,
      start_date:,
      end_date:,
      projects:,
      coc_codes: nil,
      period_type: nil,
      directive: nil,
      hash_status: nil,
      faked_pii: false,
      include_deleted: false,
      faked_environment: :development,
      confidential: false,
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
      @coc_codes = coc_codes
      @period_type = period_type.presence || 3
      @directive = directive.presence || 2
      @hash_status = hash_status.presence || 1
      @faked_pii = faked_pii
      @user = ::User.find(user_id)
      @include_deleted = include_deleted
      @faked_environment = faked_environment
      @confidential = confidential
    end

    def export!
      create_export_directory
      begin
        set_time_format
        setup_export

        export_class = HmisCsvTwentyTwentyTwo::Exporter::Export
        export_opts = {
          hmis_class: GrdaWarehouse::Hud::Export,
          export: @export,
        }
        HmisCsvTwentyTwentyTwo::Exporter::KibaExport.export!(
          options: export_opts,
          source_class: Kiba::Common::Sources::Enumerable,
          source_config: export_class.export_scope(**export_opts),
          transforms: export_class.transforms,
          dest_class: HmisCsvTwentyTwentyTwo::Exporter::CsvDestination,
          dest_config: {
            hmis_class: export_opts[:hmis_class],
            output_file: File.join(@file_path, 'Export.csv'),
          },
        )
        exportable_files.each do |destination_class, opts|
          opts[:export] = @export
          HmisCsvTwentyTwentyTwo::Exporter::KibaExport.export!(
            options: options,
            source_class: HmisCsvTwentyTwentyTwo::Exporter::RailsSource,
            source_config: destination_class.export_scope(**opts),
            transforms: destination_class.transforms,
            dest_class: HmisCsvTwentyTwentyTwo::Exporter::CsvDestination,
            dest_config: {
              hmis_class: opts[:hmis_class],
              output_file: File.join(@file_path, file_name_for(destination_class)),
            },
          )
        end

        # export_project_cocs
        # export_organizations
        # export_inventories
        # export_funders
        # export_affiliations

        # # Enrollment related
        # export_enrollments
        # export_exits
        # export_clients
        # export_enrollment_cocs
        # export_disabilities
        # export_employment_educations
        # export_health_and_dvs
        # export_income_benefits
        # export_services
        # export_current_living_situations
        # export_assessments
        # export_assessment_questions
        # export_assessment_results
        # export_events
        # export_youth_education_statuses

        # export_users

        # build_export_file
        #   zip_archive
        #   upload_zip
        #   save_fake_data
        # ensure
        #   remove_export_files
        #   reset_time_format
      end
      @export
    end

    def export_project_cocs
      project_coc_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_inventories
      inventory_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_funders
      funder_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_affiliations
      affiliation_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
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
        coc_codes: @coc_codes,
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
        coc_codes: @coc_codes,
      )
    end

    def export_employment_educations
      employment_education_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
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
        coc_codes: @coc_codes,
      )
    end

    def export_income_benefits
      income_benefits_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_services
      service_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_current_living_situations
      current_living_situation_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_assessments
      assessment_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_assessment_questions
      assessment_question_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_assessment_results
      assessment_result_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_events
      event_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
      )
    end

    def export_youth_education_statuses
      youth_education_status_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export,
        coc_codes: @coc_codes,
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

    def file_name_for(klass)
      exportable_files[klass][:hmis_class].hud_csv_file_name(version: '2022')
    end

    def exportable_files
      {
        # 'Affiliation.csv' => HmisCsvTwentyTwentyTwo::Exporter::Affiliation,
        # 'Client.csv' => client_source,
        # 'Disabilities.csv' => disability_source,
        # 'EmploymentEducation.csv' => employment_education_source,
        # 'Enrollment.csv' => enrollment_source,
        # 'EnrollmentCoC.csv' => enrollment_coc_source,
        # 'Exit.csv' => exit_source,
        # 'Export.csv' => export_source,
        # 'Funder.csv' => funder_source,
        # 'HealthAndDV.csv' => health_and_dv_source,
        # 'IncomeBenefits.csv' => income_benefits_source,
        # 'Inventory.csv' => inventory_source,
        HmisCsvTwentyTwentyTwo::Exporter::Organization => {
          hmis_class: GrdaWarehouse::Hud::Organization,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Project => {
          hmis_class: GrdaWarehouse::Hud::Project,
          project_scope: project_scope,
        },

        HmisCsvTwentyTwentyTwo::Exporter::Enrollment => {
          hmis_class: GrdaWarehouse::Hud::Enrollment,
          enrollment_scope: enrollment_scope,
          project_scope: project_scope,
        },
        # 'ProjectCoC.csv' => project_coc_source,
        # 'Services.csv' => service_source,
        # 'CurrentLivingSituation.csv' => current_living_situation_source,
        # 'Assessment.csv' => assessment_source,
        # 'AssessmentQuestions.csv' => assessment_question_source,
        # 'AssessmentResults.csv' => assessment_result_source,
        # 'Event.csv' => event_source,
        # 'YouthEducationStatus.csv' => youth_education_status_source,
        # NOTE: User must be last since we collect user_ids from the other files
        HmisCsvTwentyTwentyTwo::Exporter::User => {
          hmis_class: GrdaWarehouse::Hud::User,
          project_scope: project_scope,
        },

      }.freeze
    end

    def self.client_source
      GrdaWarehouse::Hud::Client
    end

    def client_source
      self.class.client_source
    end

    def self.enrollment_source
      GrdaWarehouse::Hud::Enrollment
    end

    def enrollment_source
      self.class.enrollment_source
    end

    def self.project_source
      GrdaWarehouse::Hud::Project
    end

    def project_source
      self.class.project_source
    end
  end
end
