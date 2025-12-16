###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'zip'
require 'csv'
require 'kiba-common/sources/enumerable'

# Testing notes
# reload!; rh = GrdaWarehouse::RecurringHmisExport.last; rh.run

# @see docs/features/hmis-csv-export.md
module HmisCsvTwentyTwentySix::Exporter
  class Base
    include ArelHelper
    include ::Export::Exporter
    include ::Export::Scopes

    attr_accessor :file_path, :version, :export, :include_deleted

    def initialize( # rubocop:disable  Metrics/ParameterLists
      version: '2026',
      user_id:,
      start_date:,
      end_date:,
      projects:,
      coc_codes: [],
      enforce_project_date_scope: false,
      period_type: nil,
      directive: nil,
      hash_status: nil,
      faked_pii: false,
      include_deleted: false,
      faked_environment: :development,
      confidential: false,
      options: {},
      file_path: 'var/hmis_export',
      debug: true,
      custom_file_types: []
    )
      setup_notifier('HMIS Exporter 2026')
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
      @enforce_project_date_scope = enforce_project_date_scope
      @selected_options = options
      @custom_file_types = custom_file_types || []
      # We also provide CoC Codes via options, make sure those are added to any CoC codes provided for backwards
      # compatibility with old code
      @coc_codes += options['coc_codes'] if options['coc_codes'].present?
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

        export_class = HmisCsvTwentyTwentySix::Exporter::Export
        export_opts = {
          hmis_class: GrdaWarehouse::Hud::Export,
          export: @export,
        }
        HmisCsvTwentyTwentySix::Exporter::KibaExport.export!(
          options: export_opts,
          source_class: Kiba::Common::Sources::Enumerable,
          source_config: export_class.export_scope(**export_opts),
          transforms: export_class.transforms,
          dest_class: HmisCsvTwentyTwentySix::Exporter::CsvDestination,
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
            # Table names can't be longer than 63 characters, so we need to truncate the prefix
            # we add roughly 13 characters below, so we'll truncate to 50 characters
            tmp_table_prefix = opts[:hmis_class].table_name.downcase[0..50]
            dest_config = {
              hmis_class: opts[:hmis_class],
              destination_class: destination_class,
              output_file: File.join(@file_path, file_name_for(destination_class)),
            }
            tmp_table_name = "te_#{tmp_table_prefix}_#{export.id}s"[0..63]
            opts[:temp_class] = TempExport.create_temporary_table(table_name: tmp_table_name, model_name: destination_class.temp_model_name)
            begin
              HmisCsvTwentyTwentySix::Exporter::KibaExport.export!(
                options: options,
                source_class: HmisCsvTwentyTwentySix::Exporter::RailsSource,
                source_config: destination_class.export_scope(**opts),
                transforms: destination_class.transforms,
                dest_class: HmisCsvTwentyTwentySix::Exporter::CsvDestination,
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
      return 'Export.csv' if klass == HmisCsvTwentyTwentySix::Exporter::Export

      # Handle custom file classes
      return klass.custom_file_name if klass.ancestors.include?(HmisCsvTwentyTwentySix::Exporter::Custom::Base)

      hmis_class_for(klass).hud_csv_file_name(version: '2026')
    end

    def self.class_mappings
      {
        HmisCsvTwentyTwentySix::Exporter::Organization => {
          hmis_class: GrdaWarehouse::Hud::Organization,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Project => {
          hmis_class: GrdaWarehouse::Hud::Project,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Inventory => {
          hmis_class: GrdaWarehouse::Hud::Inventory,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::ProjectCoc => {
          hmis_class: GrdaWarehouse::Hud::ProjectCoc,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Affiliation => {
          hmis_class: GrdaWarehouse::Hud::Affiliation,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Funder => {
          hmis_class: GrdaWarehouse::Hud::Funder,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Enrollment => {
          hmis_class: GrdaWarehouse::Hud::Enrollment,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Client => {
          hmis_class: GrdaWarehouse::Hud::Client,
          scope: :client_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Exit => {
          hmis_class: GrdaWarehouse::Hud::Exit,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Disability => {
          hmis_class: GrdaWarehouse::Hud::Disability,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::EmploymentEducation => {
          hmis_class: GrdaWarehouse::Hud::EmploymentEducation,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::IncomeBenefit => {
          hmis_class: GrdaWarehouse::Hud::IncomeBenefit,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::HealthAndDv => {
          hmis_class: GrdaWarehouse::Hud::HealthAndDv,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::CurrentLivingSituation => {
          hmis_class: GrdaWarehouse::Hud::CurrentLivingSituation,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Service => {
          hmis_class: GrdaWarehouse::Hud::Service,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Assessment => {
          hmis_class: GrdaWarehouse::Hud::Assessment,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::AssessmentQuestion => {
          hmis_class: GrdaWarehouse::Hud::AssessmentQuestion,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::AssessmentResult => {
          hmis_class: GrdaWarehouse::Hud::AssessmentResult,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::Event => {
          hmis_class: GrdaWarehouse::Hud::Event,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::YouthEducationStatus => {
          hmis_class: GrdaWarehouse::Hud::YouthEducationStatus,
          scope: :enrollment_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::HmisParticipation => {
          hmis_class: GrdaWarehouse::Hud::HmisParticipation,
          scope: :project_scope,
        },
        HmisCsvTwentyTwentySix::Exporter::CeParticipation => {
          hmis_class: GrdaWarehouse::Hud::CeParticipation,
          scope: :project_scope,
        },
        # NOTE: User must be last since we collect user_ids from the other files
        HmisCsvTwentyTwentySix::Exporter::User => {
          hmis_class: GrdaWarehouse::Hud::User,
          scope: :project_scope,
        },
      }
    end

    def custom_file_mappings
      return {} if @custom_file_types.blank?

      mappings = {}
      @custom_file_types.each do |filename|
        definition = HmisCsvTwentyTwentySix.custom_files_config.find_definition(filename)
        next unless definition

        # Dynamically determine the exporter class name
        exporter_class_name = "HmisCsvTwentyTwentySix::Exporter::Custom::#{definition.class_name}"
        importer_class_name = "HmisCsvTwentyTwentySix::Importer::Custom::#{definition.class_name}"

        exporter_class = exporter_class_name.constantize
        importer_class = importer_class_name.constantize

        # Determine scope based on what warehouse table is augmented
        scope_name = case definition.augments_warehouse_table
        when 'GrdaWarehouse::Hud::Client'
          :client_scope
        when 'GrdaWarehouse::Hud::Enrollment'
          :enrollment_scope
        when 'GrdaWarehouse::Hud::Project', 'GrdaWarehouse::Hud::Organization'
          :project_scope
        else
          :project_scope # For custom files that don't augment a warehouse table, we default to project scope, so we can fetch the data source ids.
        end

        mappings[exporter_class] = {
          hmis_class: importer_class,
          scope: scope_name,
        }
      end
      mappings
    end

    def exportable_files
      standard_files = self.class.class_mappings.map do |export_class, details|
        [
          export_class,
          {
            hmis_class: hmis_class(details[:hmis_class]),
            details[:scope] => send(details[:scope]),
          },
        ]
      end.to_h

      # Add custom files if requested
      custom_files = custom_file_mappings.map do |export_class, details|
        [
          export_class,
          {
            hmis_class: details[:hmis_class],
            # Pass all available scopes to custom files since they may need multiple scopes
            project_scope: project_scope,
            client_scope: client_scope,
            enrollment_scope: enrollment_scope,
          },
        ]
      end.to_h

      standard_files.merge(custom_files).freeze
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
