###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; HmisCsvTwentyTwenty::Importer::Importer.new(loader_id: 81, data_source_id: 90, debug: true).import!

module HmisCsvTwentyTwenty::Importer
  class Importer
    include TsqlImport
    include NotifierConfig
    include HmisTwentyTwenty

    attr_accessor :logger, :notifier_config, :import, :range, :data_source, :importer_log

    SELECT_BATCH_SIZE = 10_000
    INSERT_BATCH_SIZE = 2_000

    def initialize(
      loader_id:,
      data_source_id:,
      logger: Rails.logger,
      debug: true,
      deidentified: false
    )
      setup_notifier('HMIS CSV Importer 2020')
      @loader_log = HmisCsvTwentyTwenty::Loader::LoaderLog.find(loader_id.to_i)
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @logger = logger
      @debug = debug

      @deidentified = deidentified
      @importer_log = setup_import
      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
      log('De-identifying clients') if @deidentified
      log('Limiting to white-listed projects') if @project_whitelist
    end

    def self.module_scope
      'HmisCsvTwentyTwenty::Importer'
    end

    def import!
      return if already_running_for_data_source?

      GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{data_source.id}") do
        start_import
        pre_process!

        # Mark everything that exists in the warehouse, that would be covered by this import
        # as pending deletion.  We'll remove the pending where appropriate
        mark_tree_as_dead(Date.current)

        # Add any records we don't have
        add_new_data

        # Determine which records have changed and are newer

        # we know organizations (never delete here)
        # we know projects (never delete here)
        # we know involved projects (funder, affiliation, etc.)
        # we know involved projects and date ranges (for inventory)
        # we know involved projects and date ranges (for enrollments)
        # Pass 0, Walk the tree starting from projects and mark all as dead (in date range where appropriate)
        # Pass 1, create any where hud-key isn't in warehouse in same data source and involved projects
        # Pass 2, pluck previous hash and DateUpdated from warehouse, joining on involved scope
        # If hash is the same, mark as live
        # If hash differs
        # if the incoming DateUpdated is older, mark warehouse as live
        # If the incoming DateUpdated is the same or newer, update warehouse from lake,
        # mark warehouse live
        # mark client demographics dirty
        # mark enrollment dirty
        # if exit record changes also mark associated enrollment dirty
        # Delete all marked as dead for data source
        # For any enrollments where history_generated_on is blank? || history_generated_on < Exit.ExitDate run equivalent of:
        # GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)
        # In here, add history_generated_on date to enrollment record

        # For each project involved:
        # 1. Find related project items from warehouse and mark anything we
      end
    end

    # Move all data from the data lake
    def pre_process!
      importer_log.update(status: :pre_processing)

      # TODO: This could be parallelized
      importable_files.each do |file_name, klass|
        batch = []
        source_data_scope_for(file_name).find_each(batch_size: SELECT_BATCH_SIZE) do |source|
          destination = klass.new_from(source, deidentified: @deidentified)
          destination.importer_log_id = importer_log.id
          destination.pre_processed_at = Time.current
          destination.set_processed_as
          destination.run_row_validations

          batch << destination
          if batch.count == INSERT_BATCH_SIZE
            save_batch(klass, batch, file_name)
            batch = []
          end
        end
        if batch.present?
          save_batch(klass, batch, file_name) # ensure we get the last batch
        end
      end
    end

    def involved_project_ids
      @involved_project_ids = HmisCsvTwentyTwenty::Importer::Project.pluck(:ProjectID)
    end

    def mark_tree_as_dead(pending_date_deleted)
      importable_files.each_value do |klass|
        klass.mark_tree_as_dead(
          data_source_id: data_source.id,
          project_ids: involved_project_ids,
          date_range: date_range,
          pending_date_deleted: pending_date_deleted,
        )
      end
    end

    def add_new_data
      importable_files.each_value do |klass|
        log("Adding new #{klass.names}")
        klass.add_new_data(
          data_source_id: data_source.id,
          project_ids: involved_project_ids,
          date_range: date_range,
          importer_log_id: importer_log.id,
        )
      end
    end

    private def save_batch(klass, batch, file_name)
      if batch.count == INSERT_BATCH_SIZE
        klass.import(batch)
        lines_processed(file_name, batch.count)
      end
    rescue StandardError
      begin
        batch.each(&:save!)
      rescue StandardError => e
        add_error(klass: klass, source_id: destination.source_id, message: e.messages)
      end
    end

    private def source_data_scope_for(file_name)
      @loaded_files ||= @loader_log.class.importable_files
      @loaded_files[file_name].where(loader_id: @loader_log.id)
    end

    def date_range
      @date_range ||= Filters::DateRange.new(
        start: export_record.ExportStartDate.to_date,
        end: export_record.ExportEndDate.to_date,
      )
    end

    private def export_record
      @export_record ||= HmisCsvTwentyTwenty::Importer::Export.find_by(importer_log_id: importer_log.id)
    end

    def set_involved_projects
      # FIXME
      # project_source.load_from_csv(
      #   file_path: @file_path,
      #   data_source_id: data_source.id
      # )
    end

    def already_running_for_data_source?
      running = GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{data_source.id}")
      logger.warn "Import of Data Source: #{data_source.short_name} already running...exiting" if running
      running
    end

    def complete_import
      data_source.update(last_imported_at: Time.zone.now)
      importer_log.completed_at = Time.zone.now
      importer_log.upload_id = @upload.id if @upload.present?
      importer_log.save
    end

    def import_class(klass)
      # FIXME
      log("Importing #{klass.name}")
      begin
        file = importable_files.key(klass)
        return unless importer_log.summary[file].present?

        stats = klass.import_related!(
          data_source_id: data_source.id,
          file_path: @file_path,
          stats: importer_log.summary[file],
          soft_delete_time: @soft_delete_time,
        )
        errors = stats.delete(:errors)

        importer_log.summary[klass.file_name].merge!(stats)
        if errors.present?
          errors.each do |error|
            add_error(klass: klass, source_id: source_id, message: error[:message])
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        message = "Unable to import #{klass.name}: #{e.message}"
        add_error(file_path: klass.file_name, message: message, line: '')
      end
    end

    # def mark_upload_complete
    #   @upload.update(percent_complete: 100, completed_at: importer_log.completed_at)
    # end

    def import_old!
      # return if already_running_for_data_source?
      # Provide Application locking so we can be sure we aren't already importing this data source
      GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{data_source.id}") do
        @export = HmisCsvTwentyTwenty::Loader::Export.find_by(loader_id: importer_log.id)
        return unless export_file_valid?

        begin
          @range = set_date_range
          clean_source_files
          # reload the export file with new export id
          @export = nil
          @export = load_export_file
          @export.effective_export_end_date = @effective_export_end_date
          @export.import!
          @projects = set_involved_projects
          @projects.each(&:import!)
          # Import data that's not directly related to enrollments
          remove_project_related_data
          import_organizations
          import_inventories
          import_project_cocs
          import_funders
          import_affiliations
          import_users
          importer_log.save

          # Clients
          import_clients
          importer_log.save

          # Enrollment related
          remove_enrollment_related_data
          import_enrollments
          import_enrollment_cocs
          import_disabilities
          import_employment_educations
          import_exits
          import_health_and_dvs
          import_income_benefits
          importer_log.save
          import_services
          importer_log.save
          import_current_living_situations
          import_assessments
          import_assessment_questions
          import_assessment_results
          import_events

          complete_import
          log('Import complete')
          # ensure
          # FIXME
        end
      end # end with_advisory_lock
    end

    def import_enrollments
      import_class(enrollment_source)
    end

    def import_exits
      import_class(exit_source)
    end

    def import_services
      import_class(service_source)
    end

    def import_enrollment_cocs
      import_class(enrollment_coc_source)
    end

    def import_disabilities
      import_class(disability_source)
    end

    def import_employment_educations
      import_class(employment_education_source)
    end

    def import_health_and_dvs
      import_class(health_and_dv_source)
    end

    def import_income_benefits
      import_class(income_benefits_source)
    end

    def import_users
      import_class(user_source)
    end

    def import_current_living_situations
      import_class(current_living_situation_source)
    end

    def import_assessments
      import_class(assessment_source)
    end

    def import_assessment_questions
      import_class(assessment_question_source)
    end

    def import_assessment_results
      import_class(assessment_result_source)
    end

    def import_events
      import_class(event_source)
    end

    # This dump should be authoritative for any enrollment that was open during the
    # specified date range at any of the involved projects
    # Models this needs to handle
    # Enrollment
    # EnrollmentCoc
    # Disability
    # EmploymentEducation
    # Exit
    # HealthAndDv
    # IncomeBenefit
    # Services
    def remove_enrollment_related_data
      [
        enrollment_coc_source,
        disability_source,
        employment_education_source,
        health_and_dv_source,
        income_benefits_source,
        service_source,
        current_living_situation_source,
        assessment_source,
        assessment_question_source,
        assessment_result_source,
        event_source,
      ].each do |klass|
        next unless importer_log.summary[klass.file_name].present?

        importer_log.summary[klass.file_name][:lines_restored] -= klass.public_send(
          :delete_involved,
          {
            projects: @projects,
            range: @range,
            data_source_id: data_source.id,
            deleted_at: @soft_delete_time,
          },
        )
      end

      # Exit and Enrollment are used in the calculation, so this has to be two steps.
      involved_exit_ids = exit_source.involved_exits(projects: @projects, range: @range, data_source_id: data_source.id)
      involved_exit_ids.each_slice(1000) do |ids|
        exit_source.where(id: ids).update_all(pending_date_deleted: @soft_delete_time)
      end
      importer_log.summary['Exit.csv'][:lines_restored] -= involved_exit_ids.size
      involved_enrollment_ids = enrollment_source.involved_enrollments(projects: @projects, range: @range, data_source_id: data_source.id)
      involved_enrollment_ids.each_slice(1000) do |ids|
        enrollment_source.where(id: ids).update_all(pending_date_deleted: @soft_delete_time)
      end
      importer_log.summary['Enrollment.csv'][:lines_restored] -= involved_enrollment_ids.size
    end

    # This dump should be authoritative for any inventory and ProjectCoC
    # that is connected to an included project
    def remove_project_related_data
      [
        inventory_source,
        project_coc_source,
        funder_source,
        affiliation_source,
      ].each do |klass|
        next unless importer_log.summary[klass.file_name].present?

        importer_log.summary[klass.file_name][:lines_restored] -= klass.public_send(
          :delete_involved,
          {
            projects: @projects,
            range: @range,
            data_source_id: data_source.id,
            deleted_at: @soft_delete_time,
          },
        )
      end
    end

    def import_clients
      import_class(client_source)
    end

    def import_organizations
      import_class(organization_source)
    end

    def import_inventories
      import_class(inventory_source)
    end

    def import_project_cocs
      import_class(project_coc_source)
    end

    def import_funders
      import_class(funder_source)
    end

    def import_affiliations
      import_class(affiliation_source)
    end

    def lines_processed(file, line_count)
      importer_log.summary[file]['lines_processed'] += line_count
    end

    def setup_summary(file)
      importer_log.summary ||= {}
      importer_log.summary[file] ||= {
        'total_lines' => 0,
        'lines_processed' => 0,
        'lines_added' => 0,
        'lines_updated' => 0,
        'lines_restored' => 0,
        'lines_skipped' => 0,
        'total_errors' => 0,
      }
    end

    def importable_files
      self.class.importable_files
    end

    def self.affiliation_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Affiliation
    end

    def affiliation_source
      self.class.affiliation_source
    end

    def self.client_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Client
    end

    def client_source
      self.class.client_source
    end

    def self.disability_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Disability
    end

    def disability_source
      self.class.disability_source
    end

    def self.employment_education_source
      GrdaWarehouse::Import::HmisTwentyTwenty::EmploymentEducation
    end

    def employment_education_source
      self.class.employment_education_source
    end

    def self.enrollment_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Enrollment
    end

    def enrollment_source
      self.class.enrollment_source
    end

    def self.enrollment_coc_source
      GrdaWarehouse::Import::HmisTwentyTwenty::EnrollmentCoc
    end

    def enrollment_coc_source
      self.class.enrollment_coc_source
    end

    def self.exit_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Exit
    end

    def exit_source
      self.class.exit_source
    end

    def self.funder_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Funder
    end

    def funder_source
      self.class.funder_source
    end

    def self.health_and_dv_source
      GrdaWarehouse::Import::HmisTwentyTwenty::HealthAndDv
    end

    def health_and_dv_source
      self.class.health_and_dv_source
    end

    def self.income_benefits_source
      GrdaWarehouse::Import::HmisTwentyTwenty::IncomeBenefit
    end

    def income_benefits_source
      self.class.income_benefits_source
    end

    def self.inventory_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Inventory
    end

    def inventory_source
      self.class.inventory_source
    end

    def self.organization_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Organization
    end

    def organization_source
      self.class.organization_source
    end

    def self.project_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Project
    end

    def project_source
      self.class.project_source
    end

    def self.project_coc_source
      GrdaWarehouse::Import::HmisTwentyTwenty::ProjectCoc
    end

    def project_coc_source
      self.class.project_coc_source
    end

    def self.service_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Service
    end

    def service_source
      self.class.service_source
    end

    def self.current_living_situation_source
      GrdaWarehouse::Import::HmisTwentyTwenty::CurrentLivingSituation
    end

    def current_living_situation_source
      self.class.current_living_situation_source
    end

    def self.assessment_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Assessment
    end

    def assessment_source
      self.class.assessment_source
    end

    def self.assessment_question_source
      GrdaWarehouse::Import::HmisTwentyTwenty::AssessmentQuestion
    end

    def assessment_question_source
      self.class.assessment_question_source
    end

    def self.assessment_result_source
      GrdaWarehouse::Import::HmisTwentyTwenty::AssessmentResult
    end

    def assessment_result_source
      self.class.assessment_result_source
    end

    def self.event_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Event
    end

    def event_source
      self.class.event_source
    end

    def self.user_source
      GrdaWarehouse::Import::HmisTwentyTwenty::User
    end

    def user_source
      self.class.user_source
    end

    def setup_import
      importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.new
      importer_log.created_at = Time.now
      importer_log.data_source = data_source
      importer_log.summary = {}
      importer_log.save
      importer_log
    end

    def start_import
      importer_log.update(status: :started)
      @loader_log.update(importer_log_id: importer_log.id)
    end

    def log(message)
      # Slack really doesn't like it when you send too many message in a row
      sleep(1)
      begin
        @notifier&.ping message
      rescue Slack::Notifier::APIError
        sleep(3)
        logger.error 'Failed to send slack'
      end
      logger.info message if @debug
    end

    def add_error(klass:, source_id:, message:)
      importer_log.import_errors.create(
        source_type: klass,
        source_id: source_id,
        message: "Error importing #{klass}",
        details: message,
      )
      @loader_log_log.summary[file]['total_errors'] += 1
      log(message)
    end
  end
end
