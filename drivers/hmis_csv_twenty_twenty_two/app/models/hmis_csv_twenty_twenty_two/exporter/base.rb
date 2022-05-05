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
      @user = ::User.find_by(id: user_id)
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
            output_file: File.join(@file_path, file_name_for(destination_class)),
          },
        )
        exportable_files.each do |destination_class, opts|
          opts[:export] = @export
          options[:export] = @export
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
        zip_archive
        upload_zip
        save_fake_data
      ensure
        remove_export_files
        reset_time_format
      end
      @export
    end

    def file_name_for(klass)
      return 'Export.csv' if klass == HmisCsvTwentyTwentyTwo::Exporter::Export

      hmis_class_for(klass).hud_csv_file_name(version: '2022')
    end

    def hmis_class_for(klass)
      exportable_files[klass][:hmis_class]
    end

    def exportable_files
      {
        HmisCsvTwentyTwentyTwo::Exporter::Organization => {
          hmis_class: GrdaWarehouse::Hud::Organization,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Project => {
          hmis_class: GrdaWarehouse::Hud::Project,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Inventory => {
          hmis_class: GrdaWarehouse::Hud::Inventory,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc => {
          hmis_class: GrdaWarehouse::Hud::ProjectCoc,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Affiliation => {
          hmis_class: GrdaWarehouse::Hud::Affiliation,
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Funder => {
          hmis_class: GrdaWarehouse::Hud::Funder,
          project_scope: project_scope,
        },

        HmisCsvTwentyTwentyTwo::Exporter::Enrollment => {
          hmis_class: GrdaWarehouse::Hud::Enrollment,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Exit => {
          hmis_class: GrdaWarehouse::Hud::Exit,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc => {
          hmis_class: GrdaWarehouse::Hud::EnrollmentCoc,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Disability => {
          hmis_class: GrdaWarehouse::Hud::Disability,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::EmploymentEducation => {
          hmis_class: GrdaWarehouse::Hud::EmploymentEducation,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::IncomeBenefit => {
          hmis_class: GrdaWarehouse::Hud::IncomeBenefit,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::HealthAndDv => {
          hmis_class: GrdaWarehouse::Hud::HealthAndDv,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::CurrentLivingSituation => {
          hmis_class: GrdaWarehouse::Hud::CurrentLivingSituation,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Service => {
          hmis_class: GrdaWarehouse::Hud::Service,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Assessment => {
          hmis_class: GrdaWarehouse::Hud::Assessment,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::AssessmentQuestion => {
          hmis_class: GrdaWarehouse::Hud::AssessmentQuestion,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::AssessmentResult => {
          hmis_class: GrdaWarehouse::Hud::AssessmentResult,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::Event => {
          hmis_class: GrdaWarehouse::Hud::Event,
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyTwo::Exporter::YouthEducationStatus => {
          hmis_class: GrdaWarehouse::Hud::YouthEducationStatus,
          enrollment_scope: enrollment_scope,
        },
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
