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
module HmisCsvImporter::TwentyTwenty::Importer
  class Base < HmisCsvImporter::Import
    include TsqlImport
    include NotifierConfig
    include Shared

    attr_accessor :logger, :notifier_config, :import, :range

    def initialize(
      file_path: File.join('tmp', 'hmis_import'),
      data_source_id: ,
      logger: Rails.logger,
      debug: true,
      remove_files: true,
      deidentified: false,
      project_whitelist: false
    )
      setup_notifier('HMIS CSV Importer 2020')
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @file_path = file_path
      @logger = logger
      @debug = debug
      @soft_delete_time = Time.now.change(usec: 0) # Active Record milliseconds and Rails don't always agree, so zero those out so future comparisons work.
      @remove_files = remove_files
      @deidentified = deidentified
      @project_whitelist = project_whitelist
      setup_import(data_source: @data_source)
      log("De-identifying clients") if @deidentified
      log("Limiting to white-listed projects") if @project_whitelist
    end

    def import!
      # return if already_running_for_data_source?
      # Provide Application locking so we can be sure we aren't already importing this data source
      GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{@data_source.id}") do
        @export = load_export_file()
        return unless export_file_valid?

        begin
          @range = set_date_range()
          clean_source_files()
          # reload the export file with new export id
          @export = nil
          @export = load_export_file()
          @export.effective_export_end_date = @effective_export_end_date
          @export.import!
          @projects = set_involved_projects()
          @projects.each(&:import!)
          # Import data that's not directly related to enrollments
          remove_project_related_data()
          import_organizations()
          import_inventories()
          import_project_cocs()
          import_funders()
          import_affiliations()
          import_users()
          @import.save

          # Clients
          import_clients()
          @import.save

          # Enrollment related
          remove_enrollment_related_data()
          import_enrollments()
          import_enrollment_cocs()
          import_disabilities()
          import_employment_educations()
          import_exits()
          import_health_and_dvs()
          import_income_benefits()
          @import.save
          import_services()
          @import.save
          import_current_living_situations()
          import_assessments()
          import_assessment_questions()
          import_assessment_results()
          import_events()

          complete_import()
          log("Import complete")
        ensure
          remove_import_files() if @remove_files
        end
      end # end with_advisory_lock
    end

    def import_enrollments()
      import_class(enrollment_source)
    end

    def import_exits()
      import_class(exit_source)
    end

    def import_services()
      import_class(service_source)
    end

    def import_enrollment_cocs()
      import_class(enrollment_coc_source)
    end

    def import_disabilities()
      import_class(disability_source)
    end

    def import_employment_educations()
      import_class(employment_education_source)
    end

    def import_health_and_dvs()
      import_class(health_and_dv_source)
    end

    def import_income_benefits()
      import_class(income_benefits_source)
    end

    def import_users()
      import_class(user_source)
    end

    def import_current_living_situations()
      import_class(current_living_situation_source)
    end

    def import_assessments()
      import_class(assessment_source)
    end

    def import_assessment_questions()
      import_class(assessment_question_source)
    end

    def import_assessment_results()
      import_class(assessment_result_source)
    end

    def import_events()
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
        file = importable_files.key(klass)
        next unless @import.summary[klass.file_name].present?
        @import.summary[klass.file_name][:lines_restored] -= klass.public_send(:delete_involved, {
          projects: @projects,
          range: @range,
          data_source_id: @data_source.id,
          deleted_at: @soft_delete_time,
        })
      end

      # Exit and Enrollment are used in the calculation, so this has to be two steps.
      involved_exit_ids = exit_source.involved_exits(projects: @projects, range: @range, data_source_id: @data_source.id)
      involved_exit_ids.each_slice(1000) do |ids|
        exit_source.where(id: ids).update_all(pending_date_deleted: @soft_delete_time)
      end
      @import.summary['Exit.csv'][:lines_restored] -= involved_exit_ids.size
      involved_enrollment_ids = enrollment_source.involved_enrollments(projects: @projects, range: @range, data_source_id: @data_source.id)
      involved_enrollment_ids.each_slice(1000) do |ids|
        enrollment_source.where(id: ids).update_all(pending_date_deleted: @soft_delete_time)
      end
      @import.summary['Enrollment.csv'][:lines_restored] -= involved_enrollment_ids.size
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
        file = importable_files.key(klass)
        next unless @import.summary[klass.file_name].present?
        @import.summary[klass.file_name][:lines_restored] -= klass.public_send(:delete_involved, {
          projects: @projects,
          range: @range,
          data_source_id: @data_source.id,
          deleted_at: @soft_delete_time,
        })
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

    def setup_summary(file)
      @import.summary[file] ||= {
        total_lines: -1,
        lines_processed: 0,
        lines_added: 0,
        lines_updated: 0,
        lines_restored: 0,
        lines_skipped: 0,
        total_errors: 0,
      }
    end

    def importable_files
      self.class.importable_files
    end



    private def correct_file_names
      @correct_file_names ||= importable_files.keys.map{|m| [m.downcase, m]}
    end

    private def ensure_file_naming
      file_path = "#{@file_path}/#{@data_source.id}"
      Dir.each_child(file_path) do |filename|
        correct_file_name = correct_file_names.detect{|f, _| f == filename.downcase}&.last
        if correct_file_name.present? && correct_file_name != filename
          # Ruby complains if the files only differ by case, so we'll move it twice
          tmp_name = "tmp_#{filename}"
          FileUtils.mv(File.join(file_path, filename), File.join(file_path, tmp_name))
          FileUtils.mv(File.join(file_path, tmp_name), File.join(file_path, correct_file_name))
        end
      end
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

    def setup_import data_source:
      @import = GrdaWarehouse::ImportLog.new
      @import.created_at = Time.now
      @import.data_source = data_source
      @import.summary = {}
      @import.import_errors = {}
      @import.files = []
      @import.save
    end

    def log(message)
      # Slack really doesn't like it when you send too many message in a row
      sleep(1)
      begin
        @notifier.ping message if @notifier
      rescue Slack::Notifier::APIError => e
        sleep(3)
        logger.error "Failed to send slack"
      end
      logger.info message if @debug
    end

    def add_error(file_path:, message:, line:)
      file = File.basename(file_path)

      @import.import_errors[file] ||= []
      @import.import_errors[file] << {
         text: "Error in #{file}",
         message: message,
         line: line,
      }
      setup_summary(file)
      @import.summary[file][:total_errors] += 1
      log(message)
    end
  end
end
