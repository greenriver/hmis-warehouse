###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'zip'
require 'csv'
require 'kiba-common/sources/enumerable'

# Testing notes
# reload!; rh = GrdaWarehouse::RecurringHmisExport.last; rh.run

module HmisCsvTwentyTwentyFour::Exporter
  class Base
    include ArelHelper
    include ::Export::Exporter
    include ::Export::Scopes

    attr_accessor :file_path, :version, :export, :include_deleted

    def initialize( # rubocop:disable  Metrics/ParameterLists
      version: '2024',
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
      options: {},
      file_path: 'var/hmis_export',
      debug: true
    )
      setup_notifier('HMIS Exporter 2024')
      @version = version
      @file_path = "#{file_path}/#{Time.now.to_f}"
      @debug = debug
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
      @projects = if coc_codes.present?
        GrdaWarehouse::Hud::Project.where(id: projects).in_coc(coc_code: coc_codes).pluck(:id)
      else
        projects
      end
      @coc_codes = coc_codes
      @period_type = period_type.presence || 3
      @directive = directive.presence || 2
      @hash_status = hash_status.presence || 1
      @faked_pii = faked_pii
      @user = ::User.find_by(id: user_id)
      @include_deleted = include_deleted
      @faked_environment = faked_environment
      @confidential = confidential
      @selected_options = options
    end

    # Exports HMIS data in the specified CSV format, wrapped in a zip file.
    #
    # @param cleanup [Boolean] remove csv files from the file system when finished
    # @param zip [Boolean] create a zip file from the CSVs
    # @param upload [Boolean] store the zip file permanently
    # @return [Export] the object representing the chosen export options.
    def export!(cleanup: true, zip: true, upload: true)
      create_export_directory
      begin
        set_time_format
        setup_export

        export_class = HmisCsvTwentyTwentyFour::Exporter::Export
        export_opts = {
          hmis_class: GrdaWarehouse::Hud::Export,
          export: @export,
        }
        HmisCsvTwentyTwentyFour::Exporter::KibaExport.export!(
          options: export_opts,
          source_class: Kiba::Common::Sources::Enumerable,
          source_config: export_class.export_scope(**export_opts),
          transforms: export_class.transforms,
          dest_class: HmisCsvTwentyTwentyFour::Exporter::CsvDestination,
          dest_config: {
            hmis_class: export_opts[:hmis_class],
            destination_class: export_class,
            output_file: File.join(@file_path, file_name_for(export_class)),
          },
        )

        # You can't have an isolation level in a nested transaction (which is
        # the case if this code is called from a transactional spec. This keeps
        # the existing behavior but lets specs run as well
        maybe_in_transaction = ->(&block) do
          if GrdaWarehouse::Hud::Export.connection.open_transactions.blank?
            GrdaWarehouse::Hud::Export.transaction(isolation: :repeatable_read) do
              block.call
            end
          else
            block.call
          end
        end

        maybe_in_transaction.call do
          exportable_files.each do |destination_class, opts|
            opts[:export] = @export
            options[:export] = @export
            tmp_table_prefix = opts[:hmis_class].table_name.downcase
            dest_config = {
              hmis_class: opts[:hmis_class],
              destination_class: destination_class,
              output_file: File.join(@file_path, file_name_for(destination_class)),
            }
            opts[:temp_class] = TempExport.create_temporary_table(table_name: "temp_export_#{tmp_table_prefix}_#{export.id}s", model_name: destination_class.temp_model_name)
            begin
              HmisCsvTwentyTwentyFour::Exporter::KibaExport.export!(
                options: options,
                source_class: HmisCsvTwentyTwentyFour::Exporter::RailsSource,
                source_config: destination_class.export_scope(**opts),
                transforms: destination_class.transforms,
                dest_class: HmisCsvTwentyTwentyFour::Exporter::CsvDestination,
                dest_config: dest_config,
              )
            ensure
              opts[:temp_class].drop
            end
          end
        end
        zip_archive if zip
        upload_zip if zip && upload
        save_fake_data
        @export.update(completed_at: Time.current)
      ensure
        remove_export_files if cleanup
        reset_time_format
      end
      @export
    end

    def file_name_for(klass)
      return 'Export.csv' if klass == HmisCsvTwentyTwentyFour::Exporter::Export

      hmis_class_for(klass).hud_csv_file_name(version: '2024')
    end

    def hmis_class_for(klass)
      exportable_files[klass][:hmis_class]
    end

    def exportable_files
      {
        HmisCsvTwentyTwentyFour::Exporter::Organization => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Organization),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Project => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Project),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Inventory => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Inventory),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::ProjectCoc => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::ProjectCoc),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Affiliation => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Affiliation),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Funder => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Funder),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Enrollment => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Enrollment),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Client => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Client),
          client_scope: client_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Exit => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Exit),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Disability => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Disability),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::EmploymentEducation => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::EmploymentEducation),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::IncomeBenefit => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::IncomeBenefit),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::HealthAndDv => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::HealthAndDv),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::CurrentLivingSituation => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::CurrentLivingSituation),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Service => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Service),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Assessment => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Assessment),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::AssessmentQuestion => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::AssessmentQuestion),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::AssessmentResult => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::AssessmentResult),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::Event => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::Event),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::YouthEducationStatus => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::YouthEducationStatus),
          enrollment_scope: enrollment_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::HmisParticipation => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::HmisParticipation),
          project_scope: project_scope,
        },
        HmisCsvTwentyTwentyFour::Exporter::CeParticipation => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::CeParticipation),
          project_scope: project_scope,
        },
        # NOTE: User must be last since we collect user_ids from the other files
        HmisCsvTwentyTwentyFour::Exporter::User => {
          hmis_class: hmis_class(GrdaWarehouse::Hud::User),
          project_scope: project_scope,
        },
      }.freeze
    end

    def hmis_class(klass)
      return klass unless @include_deleted

      @classes_with_deleted ||= {
        GrdaWarehouse::Hud::Assessment => GrdaWarehouse::Hud::WithDeleted::Assessment,
        GrdaWarehouse::Hud::Client => GrdaWarehouse::Hud::WithDeleted::Client,
        GrdaWarehouse::Hud::Enrollment => GrdaWarehouse::Hud::WithDeleted::Enrollment,
        GrdaWarehouse::Hud::Inventory => GrdaWarehouse::Hud::WithDeleted::Inventory,
        GrdaWarehouse::Hud::Organization => GrdaWarehouse::Hud::WithDeleted::Organization,
        GrdaWarehouse::Hud::Project => GrdaWarehouse::Hud::WithDeleted::Project,
        GrdaWarehouse::Hud::ProjectCoc => GrdaWarehouse::Hud::WithDeleted::ProjectCoc,
        GrdaWarehouse::Hud::User => GrdaWarehouse::Hud::WithDeleted::User,
      }.freeze

      @classes_with_deleted[klass] || klass
    end

    def self.client_source(include_deleted = false)
      return GrdaWarehouse::Hud::WithDeleted::Client if include_deleted

      GrdaWarehouse::Hud::Client
    end

    def client_source
      self.class.client_source(@include_deleted)
    end

    def self.enrollment_source(include_deleted = false)
      return GrdaWarehouse::Hud::WithDeleted::Enrollment if include_deleted

      GrdaWarehouse::Hud::Enrollment
    end

    def enrollment_source
      self.class.enrollment_source(@include_deleted)
    end

    def self.project_source(include_deleted = false)
      return GrdaWarehouse::Hud::WithDeleted::Project if include_deleted

      GrdaWarehouse::Hud::Project
    end

    def project_source
      self.class.project_source(@include_deleted)
    end
  end
end
