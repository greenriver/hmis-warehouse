require 'zip'
require 'csv'
require 'charlock_holmes'
require 'newrelic_rpm'

# Assumptions:
# The import is authoratative for the date range specified in the Export.csv file
# The import is authoratative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

module Importers::HMISFiveOne
  class Base
    include TsqlImport
    include NotifierConfig

    attr_accessor :logger, :notifier_config

    def initialize(
      file_path: 'var/hmis_import',
      data_source: ,
      logger: Rails.logger, debug: true)
      setup_notifier('HMIS Importer 5.1')
      @data_source = GrdaWarehouse::DataSource.find(data_source.to_i)
      @file_path = file_path
      @logger = logger
      @debug = debug
      setup_import(data_source: @data_source)
    end
    

    def import!
      # return if already_running_for_data_source?
      # Provide Application locking so we can be sure we aren't already importing this data source
      GrdaWarehouse::DataSource.with_advisory_lock("hud_import_#{@data_source.id}") do
        @export = load_export_file()
        return unless @export.present?
        @range = set_date_range()
        clean_source_files()
        @projects = set_involved_projects()
        GrdaWarehouseBase.transaction do
          @export.import!
          @projects.each(&:update_changed_project_types)
          @projects.each(&:import!)
          # Import data that's not directly related to enrollments
          import_organizations()
          import_inventories()
          import_project_cocs()
          import_sites()
          import_funders()
          import_affiliations()
          
          # Enrollment related
          remove_enrollment_related_data()
          import_enrollments()
          import_enrollment_cocs()
          import_disabilities()
          import_employment_educations()
          import_exits()
          import_health_and_dvs()
          import_income_benefits()
          import_services()

          # Clients
          import_clients()

          remove_import_files()
          complete_import()
        end
      end # end with_advisory_lock
      binding.pry
    end

    def remove_import_files
      import_file_path = "#{@file_path}/#{@data_source.id}"
      Rails.logger.info "Removing #{import_file_path}"
      FileUtils.rm_rf(import_file_path) if File.exists?(import_file_path)
    end

    def complete_import
      @import.completed_at = Time.now
      @import.save
    end
    
    def import_enrollments()
      GrdaWarehouse::Import::HMISFiveOne::Enrollment.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_exits()
      GrdaWarehouse::Import::HMISFiveOne::Exit.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
    
    def import_services()
      GrdaWarehouse::Import::HMISFiveOne::Service.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_enrollment_cocs()
      GrdaWarehouse::Import::HMISFiveOne::EnrollmentCoc.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
    
    def import_disabilities()
      GrdaWarehouse::Import::HMISFiveOne::Disability.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_employment_educations()
      GrdaWarehouse::Import::HMISFiveOne::EmploymentEducation.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
        
    def import_health_and_dvs()
      GrdaWarehouse::Import::HMISFiveOne::HealthAndDv.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
    
    def import_income_benefits()
      GrdaWarehouse::Import::HMISFiveOne::IncomeBenefit.import_enrollment_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
    
    # This dump should be authoriative for any enrollment that was open during the 
    # specified date range at any of the involved projexts
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
      GrdaWarehouse::Import::HMISFiveOne::EnrollmentCoc.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)
      GrdaWarehouse::Import::HMISFiveOne::Disability.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)
      GrdaWarehouse::Import::HMISFiveOne::EmploymentEducation.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)
      GrdaWarehouse::Import::HMISFiveOne::HealthAndDv.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)
      GrdaWarehouse::Import::HMISFiveOne::IncomeBenefit.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)
      GrdaWarehouse::Import::HMISFiveOne::Service.delete_involved(projects: @projects, range: @range, data_source_id: @data_source.id)

      # TODO: Need to figure out how to remove exits in a way that we can still use them
      # To determine if the enrollments should be removed.
      # Exit and Enrollment are used in the calculation, so this has to be two steps.
      involved_exit_ids = GrdaWarehouse::Import::HMISFiveOne::Exit.involved_exits(projects: @projects, range: @range, data_source_id: @data_source.id)
      involved_enrollment_ids = GrdaWarehouse::Import::HMISFiveOne::Enrollment.involved_enrollments(projects: @projects, range: @range, data_source_id: @data_source.id)
      involved_exit_ids.each_slice(1000) do |ids|
        GrdaWarehouse::Import::HMISFiveOne::Exit.where(id: ids).update_all(DateDeleted: Time.now)
      end
      involved_enrollment_ids.each_slice(1000) do |ids|
        GrdaWarehouse::Import::HMISFiveOne::Enrollment.where(id: ids).update_all(DateDeleted: Time.now)
      end
    end

    def import_clients
      klass = GrdaWarehouse::Import::HMISFiveOne::Client
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_organizations
      # Maybe load up HUD Key and DateUpdated for existing in same data source
      # Loop over incoming, see if the key is there with a newer DateUpdated
      # Update if newer, create if it isn't there, otherwise do nothing
      klass = GrdaWarehouse::Import::HMISFiveOne::Organization
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_inventories
      klass = GrdaWarehouse::Import::HMISFiveOne::Inventory
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_project_cocs
      klass = GrdaWarehouse::Import::HMISFiveOne::ProjectCoc
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_sites
      klass = GrdaWarehouse::Import::HMISFiveOne::Site
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end
    
    def import_funders
      klass = GrdaWarehouse::Import::HMISFiveOne::Funder
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def import_affiliations
      klass = GrdaWarehouse::Import::HMISFiveOne::Affiliation
      @import.summary[klass.file_name].merge! klass.import_project_related!(data_source_id: @data_source.id, file_path: @file_path)
    end

    def set_involved_projects
      GrdaWarehouse::Import::HMISFiveOne::Project.load_from_csv(
        file_path: @file_path, 
        data_source_id: @data_source.id
      )
    end

    def set_date_range
      Filters::DateRange.new(start: @export.ExportStartDate.to_date, end: @export.ExportEndDate.to_date)
    end

    def load_export_file
      begin
        @export ||= GrdaWarehouse::Import::HMISFiveOne::Export.load_from_csv(
          file_path: @file_path, 
          data_source_id: @data_source.id
        )
      rescue Errno::ENOENT => exception
        log('No valid Export.csv file found')
      end
      return nil unless @export.valid?
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
        if File.exists?(destination_file_path)
          FileUtils.mv(destination_file_path, source_file_path)
        else
          # We failed at cleaning the import file, delete the source
          # So we don't accidentally import an unclean file
          File.delete(source_file_path) if File.exists?(source_file_path)
        end
      end
    end

    def clean_source_file destination_path:, read_from:, klass:
      header_row = read_from.readline
      comma_count = nil
      if header_valid?(header_row, klass)
        comma_count = header_row.count(',')
        header = CSV.parse_line(header_row)
        write_to = CSV.open(
          destination_path, 
          'wb', 
          headers: header, 
          write_headers: true,
          force_quotes: true
          )
      else
        msg = "Unable to import #{File.basename(read_from.path)}, header invalid: #{header_row}; expected a subset of: #{klass.hud_csv_headers}"
        add_error(file_path: read_from.path, message: msg)
        return
      end
      read_from.each_line do |line|
        begin
          while short_line?(line, comma_count)
            logger.warn "Found a short line in #{read_from.path}"
            line = line.gsub(/[\r\n]*/, '')
            read_from.seek(+1, IO::SEEK_CUR)
            next_line = read_from.readline
            line += next_line
            if long_line?(line, comma_count)
              bad_line = line.gsub(next_line, '')
              msg = "Unable to fix a line, not importing: #{bad_line}"
              add_error(file_path: read_from.path, message: msg)
              line = '"' + next_line
            end
          end
          begin
            row = CSV.parse_line(line, headers: header)
            if row.count == header.count
              row = set_useful_export_id(row: row, export_id: export_id_addition)
              write_to << row
              log_processed_line(file_path: read_from.path)
            else
              msg = "Line length is incorrect, unable to import: #{line}"
              add_error(file_path: read_from.path, message: msg)
            end
          rescue CSV::MalformedCSVError => exception
            message = "Failed to process line, #{exception.message}: #{line}"
            add_error(file_path: read_from.path, message: message)
          end
        rescue Exception => exception
          message = "Failed while processing #{read_from.path}, #{exception.message}: #{line}"
          add_error(file_path: read_from.path, message: message)
        end
      end
      write_to.close
    end

    def header_valid?(line, klass)
      # just make sure we don't have anything we don't know how to process
      (CSV.parse_line(line)&.map(&:to_sym) - klass.hud_csv_headers).blank?
    end

    def short_line?(line, comma_count)
      line.count(',') < comma_count
    end

    def long_line?(line, comma_count)
      line.count(',') > comma_count
    end

    def export_id_addition
      @export_id_addition ||= @range.start.strftime('%Y%m%d')
    end

    # make sure we have an ExportID in every file that 
    # reflects the start date of the export
    def set_useful_export_id(row:, export_id:)
      row['ExportID'] = "#{row['ExportID']}_#{export_id_addition}"
      row
    end

    def open_csv_file(file_path)
      # Look at the file to see if we can determine the encoding
      file_encoding = CharlockHolmes::EncodingDetector.
        detect(File.read(file_path)).
        try(:[], :encoding)
      file_lines = IO.readlines(file_path).size - 1
      log("Processing #{file_lines} lines in: #{file_path}")

      @import.summary[File.basename(file_path)] = {
        total_lines: -1,
        lines_added: 0, 
        lines_updated: 0, 
        total_errors: 0
      }
      File.open(file_path, "r:#{file_encoding}:utf-8")
    end

    def importable_files
      {
        'Affiliation.csv' => GrdaWarehouse::Import::HMISFiveOne::Affiliation,
        'Client.csv' => GrdaWarehouse::Import::HMISFiveOne::Client,
        'Disabilities.csv' => GrdaWarehouse::Import::HMISFiveOne::Disability,
        'EmploymentEducation.csv' => GrdaWarehouse::Import::HMISFiveOne::EmploymentEducation,
        'Enrollment.csv' => GrdaWarehouse::Import::HMISFiveOne::Enrollment,
        'EnrollmentCoC.csv' => GrdaWarehouse::Import::HMISFiveOne::EnrollmentCoc,
        'Exit.csv' => GrdaWarehouse::Import::HMISFiveOne::Exit,
        'Export.csv' => GrdaWarehouse::Import::HMISFiveOne::Export,
        'Funder.csv' => GrdaWarehouse::Import::HMISFiveOne::Funder,
        'HealthAndDV.csv' => GrdaWarehouse::Import::HMISFiveOne::HealthAndDv,
        'IncomeBenefits.csv' => GrdaWarehouse::Import::HMISFiveOne::IncomeBenefit,
        'Inventory.csv' => GrdaWarehouse::Import::HMISFiveOne::Inventory,
        'Organization.csv' => GrdaWarehouse::Import::HMISFiveOne::Organization,
        'Project.csv' => GrdaWarehouse::Import::HMISFiveOne::Project,
        'ProjectCoC.csv' => GrdaWarehouse::Import::HMISFiveOne::ProjectCoc,
        'Services.csv' => GrdaWarehouse::Import::HMISFiveOne::Service,
        'Site.csv' => GrdaWarehouse::Import::HMISFiveOne::Site
      }.freeze
    end

    def setup_import data_source:
      @import = GrdaWarehouse::ImportLog.new
      @import.created_at = Time.now
      @import.data_source = data_source
      @import.summary = {}
      @import.import_errors = {}
    end

    def log_processed_line file_path:
      file = File.basename(file_path)
      @import.summary[file][:total_lines] += 1
    end
    def log(message)
      @notifier.ping message if @notifier
      logger.info message if @debug
    end

    def add_error(file_path:, message:)
      file = File.basename(file_path)
      @import.import_errors[file] ||= []
      @import.import_errors[file] << message
      @import.summary[file][:total_errors] += 1
      log(message)
    end
  end
end
