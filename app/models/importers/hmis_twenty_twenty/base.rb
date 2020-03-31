###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'zip'
require 'csv'
require 'charlock_holmes'
# require 'newrelic_rpm'

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments
module Importers::HmisTwentyTwenty
  class Base
    include TsqlImport
    include NotifierConfig

    attr_accessor :logger, :notifier_config, :import, :range

    def initialize(
      file_path: 'var/hmis_import',
      data_source_id: ,
      logger: Rails.logger,
      debug: true,
      remove_files: true,
      deidentified: false,
      project_whitelist: false
    )
      setup_notifier('HMIS Importer 2020')
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
          @projects.each(&:update_changed_project_types)
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

          delete_remaining_pending_deletes()
          complete_import()
          match_clients()
          log("Import complete")
        ensure
          cleanup_any_pending_deletes()
          remove_import_files() if @remove_files
        end
      end # end with_advisory_lock
      project_cleanup() # FIXME, this should only attempt to cleanup projects within this data source
    end

    def export_file_valid?
      if @export.blank?
        log("Exiting, failed to find a valid export file")
        return false
      end
      if @data_source.source_id.present?
        source_id = @export[:SourceID]
        if @data_source.source_id.casecmp(source_id) != 0
          # Construct a valid file_path for add_error
          file_path = "#{@file_path}/#{@data_source.id}/Export.csv"
          msg = "SourceID '#{source_id}' from Export.csv does not match '#{@data_source.source_id}' specified in the data source"

          add_error(file_path: file_path, message: msg, line: '')

          # Populate @import for error reporting
          @import.files << 'Export.csv'
          @import.summary['Export.csv'][:total_lines] = 1
          complete_import()
          return false
        end
      end
      return true
    end

    def delete_remaining_pending_deletes()
      # If a pending delete is still present, the associated record is not in the import, and should be
      # marked as deleted
      soft_deletable_sources.each do |source|
        source.where(data_source_id: @data_source.id).
          where.not(pending_date_deleted: nil).
          update_all(DateDeleted: @soft_delete_time, pending_date_deleted: nil)
      end
    end

    def cleanup_any_pending_deletes
      log("Resetting pending deletes")
      # If an import fails, it will leave pending deletes. Iterate through the sources and null out any soft deletes
      soft_deletable_sources.each do |source|
        source.where(data_source_id: @data_source.id).
          where.not(pending_date_deleted: nil). # Note, postgres won't index nulls, this speeds this up tremendously
          update_all(pending_date_deleted: nil)
      end
      log("Pending deletes reset")
    end

    def remove_import_files
      import_file_path = "#{@file_path}/#{@data_source.id}"
      Rails.logger.info "Removing #{import_file_path}"
      FileUtils.rm_rf(import_file_path) if File.exists?(import_file_path)
    end

    def project_cleanup
      GrdaWarehouse::Tasks::ProjectCleanup.new(
        project_ids: GrdaWarehouse::Hud::Project.where(data_source_id: @data_source.id).select(:id)
      ).run!
    end

    def match_clients
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!
    end

    def complete_import
      @data_source.update(last_imported_at: Time.zone.now)
      @import.completed_at = Time.zone.now
      @import.upload_id = @upload.id if @upload.present?
      @import.save
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



    def self.pre_calculate_source_hashes!
      importable_files.each do |_, klass|
        klass.pre_calculate_source_hashes!
      end
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

    def import_class klass
      log("Importing #{klass.name}")
      begin
        file = importable_files.key(klass)
        return unless @import.summary[file].present?
        stats = klass.import_related!(
          data_source_id: @data_source.id,
          file_path: @file_path,
          stats: @import.summary[file],
          soft_delete_time: @soft_delete_time
        )
        errors = stats.delete(:errors)
        setup_summary(klass.file_name)
        @import.summary[klass.file_name].merge!(stats)
        if errors.present?
          errors.each do |error|
            add_error(file_path: klass.file_name, message: error[:message], line: error[:line])
          end
        end
      rescue ActiveRecord::ActiveRecordError => exception
        message = "Unable to import #{klass.name}: #{exception.message}"
        add_error(file_path: klass.file_name, message: message, line: '')
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

    def set_involved_projects
      project_source.load_from_csv(
        file_path: @file_path,
        data_source_id: @data_source.id
      )
    end

    def set_date_range
      Filters::DateRange.new(start: @export.ExportStartDate.to_date, end: @export.ExportEndDate.to_date)
    end

    def load_export_file
      begin
        @export ||= export_source.load_from_csv(
          file_path: @file_path,
          data_source_id: @data_source.id
        )
      rescue Errno::ENOENT => exception
        log('No valid Export.csv file found')
      end
      return nil unless @export&.valid?
      @export
    end

    def already_running_for_data_source?
      running = GrdaWarehouse::DataSource.advisory_lock_exists?("hud_import_#{@data_source.id}")
      if running
        logger.warn "Import of Data Source: #{@data_source.short_name} already running...exiting"
      end
      return running
    end

    def clean_source_files
      importable_files.each do |file_name, klass|
        source_file_path = "#{@file_path}/#{@data_source.id}/#{file_name}"
        next unless File.file?(source_file_path)
        destination_file_path = "#{source_file_path}_updating"
        file = open_csv_file(source_file_path)
        clean_source_file(destination_path: destination_file_path, read_from: file, klass: klass)
        @import.files << [klass.name, file_name]
        if File.exists?(destination_file_path)
          FileUtils.mv(destination_file_path, source_file_path)
        else
          # We failed at cleaning the import file, delete the source
          # So we don't accidentally import an unclean file
          File.delete(source_file_path) if File.exists?(source_file_path)
        end
      end
    end

    # Headers need to match our style
    def clean_header_row(source_headers, klass)
      indexed_headers = klass.hud_csv_headers.map do |k|
        [k.to_s.downcase, k]
      end.to_h
      source_headers.map do |k|
        indexed_headers[k.downcase].to_s
      end
    end

    def clean_source_file destination_path:, read_from:, klass:
      csv = CSV.new(read_from, headers: true)
      # read the first row so we can set the headers
      row = csv.shift
      headers = csv.headers
      csv.rewind # go back to the start for processing

      if headers.blank?
        msg = "Unable to import #{File.basename(read_from.path)}, no data"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      elsif header_valid?(headers, klass)
        # we need to accept different cased headers, but we need our
        # case for import, so we'll fix that up here and use ours going forward
        header = clean_header_row(headers, klass)
        write_to = CSV.open(
          destination_path,
          'wb',
          headers: header,
          write_headers: true,
          force_quotes: true
          )
      else
        msg = "Unable to import #{File.basename(read_from.path)}, header invalid: #{headers.to_s}; expected a subset of: #{klass.hud_csv_headers}"
        add_error(file_path: read_from.path, message: msg, line: '')
        return
      end
      # Reopen the file with corrected headers
      csv = CSV.new(read_from, headers: header)
      # since we're providing headers, skip the header row
      csv.drop(1).each do |row|
        begin
          # remove any internal newlines
          row.each{ |k,v| row[k] = v&.gsub(/[\r\n]+/, ' ')&.strip }
          case klass.name
          when 'GrdaWarehouse::Import::HmisTwentyTwenty::Client'
            row = klass.deidentify_client_name(row) if @deidentified
            row['SSN'] = row['SSN'].to_s[0..8] # limit SSNs to 9 characters
          when 'GrdaWarehouse::Import::HmisTwentyTwenty::Assessment'
            next unless row['AssessmentDate'].present? && row['AssessmentLocation'].present?
          when 'GrdaWarehouse::Import::HmisTwentyTwenty::CurrentLivingSituation'
            next unless row['CurrentLivingSituation'].present? && row['InformationDate'].present? && row['UserID'].present? && row['DateUpdated'].present? && row['DateCreated'].present? && row['EnrollmentID'].present?
          end
          if row.count == header.count
            row = set_useful_export_id(row: row, export_id: export_id_addition)
            track_max_updated(row)
            write_to << row
          else
            msg = "Line length is incorrect, unable to import:"
            add_error(file_path: read_from.path, message: msg, line: row.to_s)
          end
        rescue Exception => exception
          message = "Failed while processing #{read_from.path}, #{exception.message}:"
          add_error(file_path: read_from.path, message: message, line: row.to_s)
        end
      end
      write_to.close
    end

    def header_valid?(line, klass)
      incoming_headers = line&.map(&:downcase)&.map(&:to_sym)
      hud_headers = klass.hud_csv_headers.map(&:downcase)
      (hud_headers & incoming_headers).count == hud_headers.count
    end

    def short_line?(line, comma_count)
      CSV.parse_line(line).count < comma_count rescue line.count(',') < comma_count
    end

    def long_line?(line, comma_count)
      CSV.parse_line(line).count > (comma_count + 1) rescue line.count(',') > comma_count
    end

    def export_id_addition
      @export_id_addition ||= @range.start.strftime('%Y%m%d')
    end

    # The HMIS spec limits the field to 50 characters
    EXPORT_ID_FIELD_WIDTH = 50

    # make sure we have an ExportID in every file that
    # reflects the start date of the export
    # NOTE: The white-listing process seems to add extra commas to the CSV
    # These can break the useful export_id, so we need to remove any
    # from the existing row before tacking on the new value
    def set_useful_export_id(row:, export_id:)
      # Make sure there i enough room to append the underscore and suffix
      truncated = row['ExportID'].chomp(', ')[0, EXPORT_ID_FIELD_WIDTH - export_id.length - 1]
      row['ExportID'] = "#{truncated}_#{export_id}"
      row
    end

    # figure out the maximum date this export set was updated
    def track_max_updated(row)
      @effective_export_end_date ||= '1900-01-01'.to_date
      if row['DateUpdated'].present? && row['DateUpdated'].to_date > @effective_export_end_date
        @effective_export_end_date = row['DateUpdated'].to_date
      end
    end

    def open_csv_file(file_path)
      file = File.read(file_path)
      # Look at the file to see if we can determine the encoding
      file_encoding = CharlockHolmes::EncodingDetector.
        detect(file).
        try(:[], :encoding)
      file_lines = IO.readlines(file_path).size - 1
      setup_summary(File.basename(file_path))
      @import.summary[File.basename(file_path)][:total_lines] = file_lines
      log("Processing #{file_lines} lines in: #{file_path}")
      File.open(file_path, "r:#{file_encoding}:utf-8")
    end

    def expand file_path:
      Rails.logger.info "Expanding #{file_path}"
      Zip::File.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          Rails.logger.info entry.name
          entry.extract([@local_path, File.basename(entry.name)].join('/'))
        end
      end
      FileUtils.rm(file_path)
    end

    def mark_upload_complete
      @upload.update(percent_complete: 100, completed_at: @import.completed_at)
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

    def soft_deletable_sources
      self.class.soft_deletable_sources
      # importable_files.values - [ export_source ]
    end

    def self.soft_deletable_sources
      importable_files.values - [ export_source ]
    end

    def importable_files
      self.class.importable_files
    end

    def self.importable_files
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
      }.freeze
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

    def self.export_source
      GrdaWarehouse::Import::HmisTwentyTwenty::Export
    end
    def export_source
      self.class.export_source
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
