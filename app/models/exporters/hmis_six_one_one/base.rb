###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'zip'
require 'csv'
module Exporters::HmisSixOneOne
  class Base
    include NotifierConfig
    include ArelHelper

    attr_accessor :logger, :notifier_config, :file_path, :export

    def initialize(
      file_path: 'var/hmis_export',
      logger: Rails.logger,
      debug: true,
      start_date:,
      end_date:,
      projects:,
      period_type: 3,
      directive: 2,
      hash_status: 1,
      faked_pii: false,
      include_deleted: false,
      user_id: nil,
      faked_environment: :development
    )
      setup_notifier('HMIS Exporter 6.11')
      @file_path = "#{file_path}/#{Time.now.to_f}"
      @logger = logger
      @debug = debug
      @range = ::Filters::DateRange.new(start: start_date, end: end_date)
      @projects = projects
      @period_type = period_type
      @directive = directive
      @hash_status = hash_status
      @faked_pii = faked_pii
      @user = current_user rescue User.find(user_id)
      @include_deleted = include_deleted
      @faked_environment = faked_environment
    end

    def export!
      create_export_directory()
      begin
        set_time_format()
        setup_export()

        # Project related items
        export_projects()
        export_project_cocs()
        export_organizations()
        export_inventories()
        export_geographies()
        export_funders()
        export_affiliations()

        # Enrollment related
        export_enrollments()
        export_exits()
        export_clients()
        export_enrollment_cocs()
        export_disabilities()
        export_employment_educations()
        export_health_and_dvs()
        export_income_benefits()
        export_services()

        build_export_file()
        zip_archive()
        upload_zip()
        save_fake_data()
      ensure
        remove_export_files()
        reset_time_format()
      end
      @export
    end

    def set_time_format
      # We need this for exporting to the appropriate format
      @default_date_format = Date::DATE_FORMATS[:default]
      @default_time_format = Time::DATE_FORMATS[:default]
      Date::DATE_FORMATS[:default] = "%Y-%m-%d"
      Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    end

    def reset_time_format
      Date::DATE_FORMATS[:default] = @default_date_format
      Time::DATE_FORMATS[:default] = @default_time_format
    end

    def save_fake_data
      return unless @faked_pii
      @export.fake_data.save
    end

    def zip_path
      @zip_path ||= File.join(@file_path, "#{@export.export_id}.zip")
    end

    def upload_zip
      @export.file = Pathname.new(zip_path()).open
      @export.content_type = @export.file.content_type
      @export.content = @export.file.read
      @export.save
    end

    def zip_archive
      files = Dir.glob(File.join(@file_path, '*')).map{|f| File.basename(f)}
      Zip::File.open(zip_path(), Zip::File::CREATE) do |zipfile|
       files.each do |filename|
        zipfile.add(
          File.join(@export.export_id, filename),
          File.join(@file_path, filename)
        )
        end
      end
    end

    def remove_export_files
      FileUtils.rmtree(@file_path) if File.exists? @file_path
    end

    def export_projects
      project_source.new.export!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_project_cocs
      project_coc_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_organizations
      organization_source.new.export!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_inventories
      inventory_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_geographies
      geography_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_funders
      funder_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_affiliations
      affiliation_source.new.export_project_related!(
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_enrollments
      enrollment_source.new.export!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_enrollment_cocs
      enrollment_coc_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_clients
      client_source.new.export!(
        client_scope: client_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_disabilities
      disability_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_employment_educations
      employment_education_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_exits
      exit_source.new.export!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_health_and_dvs
      health_and_dv_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_income_benefits
      income_benefits_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def export_services
      service_source.new.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path,
        export: @export
      )
    end

    def enrollment_scope
      @enrollment_scope ||= begin
        # Choose all enrollments open during the range at one of the associated projects.
        if @export.include_deleted
          e_scope = enrollment_source.with_deleted
        else
          e_scope = enrollment_source
        end
        e_scope = e_scope.where(project_exists_for_enrollment)
        case @export.period_type
        when 3
          e_scope = e_scope.open_during_range(@range)
        when 1
        end
        e_scope
      end
    end

    def client_scope
      # include any client with an open enrollment
      # during the report period in one of the involved projects
      @client_scope ||= begin
        if @export.include_deleted
          c_scope = client_source.with_deleted
        else
          c_scope = client_source
        end
        c_scope.joins(:warehouse_client_source).
          where(enrollment_exists_for_client)
      end
    end

    def project_scope
      @project_scope ||= begin
       p_scope = project_source.where(id: @projects)
        if @export.include_deleted
          p_scope = p_scope.with_deleted
        end
        p_scope
      end
    end

    def enrollment_exists_for_client
      if @export.include_deleted
        e_scope = enrollment_source.with_deleted
      else
        e_scope = enrollment_source
      end
      case @export.period_type
      when 3
        e_scope = e_scope.open_during_range(@range)
      when 1

      end
      e_scope.where(
        e_t[:PersonalID].eq(c_t[:PersonalID]).
        and(e_t[:data_source_id].eq(c_t[:data_source_id]))
      ).where(
        project_exists_for_enrollment
      ).exists
    end


    def project_exists_for_enrollment
      project_scope.where(
        p_t[:ProjectID].eq(e_t[:ProjectID]).
        and(p_t[:data_source_id].eq(e_t[:data_source_id]))
      ).exists
    end

    def setup_export
      options = {
        user_id: @user&.id,
        start_date: @range.start,
        end_date: @range.end,
        period_type: @period_type,
        directive: @directive,
        hash_status: @hash_status,
        faked_pii: @faked_pii,
        project_ids: @projects,
        include_deleted: @include_deleted,
      }
      options[:export_id] = Digest::MD5.hexdigest(options.to_s)

      @export = GrdaWarehouse::HmisExport.create(options)
      @export.fake_data = GrdaWarehouse::FakeData.where(environment: @faked_environment).first_or_create
    end

    def create_export_directory
      # make sure the path is clean
      FileUtils.rmtree(@file_path) if File.exists? @file_path
      FileUtils.mkdir_p(@file_path)
    end

    def build_export_file
      export = export_source.new(path: @file_path)
      export.ExportID = @export.export_id
      export.SourceType = 3 # data warehouse
      export.SourceID = nil # potentially more than one CoC
      export.SourceName = _('Boston DND Warehouse')
      export.SourceContactFirst = @user&.first_name || 'Automated'
      export.SourceContactLast = @user&.last_name || 'Export'
      export.SourceContactEmail = @user&.email
      export.ExportDate = Date.current
      export.ExportStartDate = @range.start
      export.ExportEndDate = @range.end
      export.SoftwareName = _('OpenPath HMIS Warehouse')
      export.SoftwareVersion = 1
      export.ExportPeriodType = @period_type
      export.ExportDirective = @directive
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
        'Geography.csv' => geography_source,
      }.freeze
    end

    def self.affiliation_source
      GrdaWarehouse::Export::HMISSixOneOne::Affiliation
    end
    def affiliation_source
      self.class.affiliation_source
    end

    def self.client_source
      GrdaWarehouse::Export::HMISSixOneOne::Client
    end
    def client_source
      self.class.client_source
    end

    def self.disability_source
      GrdaWarehouse::Export::HMISSixOneOne::Disability
    end
    def disability_source
      self.class.disability_source
    end

    def self.employment_education_source
      GrdaWarehouse::Export::HMISSixOneOne::EmploymentEducation
    end
    def employment_education_source
      self.class.employment_education_source
    end

    def self.enrollment_source
      GrdaWarehouse::Export::HMISSixOneOne::Enrollment
    end
    def enrollment_source
      self.class.enrollment_source
    end

    def self.enrollment_coc_source
      GrdaWarehouse::Export::HMISSixOneOne::EnrollmentCoc
    end
    def enrollment_coc_source
      self.class.enrollment_coc_source
    end

    def self.exit_source
      GrdaWarehouse::Export::HMISSixOneOne::Exit
    end
    def exit_source
      self.class.exit_source
    end

    def self.export_source
      GrdaWarehouse::Export::HMISSixOneOne::Export
    end
    def export_source
      self.class.export_source
    end

    def self.funder_source
      GrdaWarehouse::Export::HMISSixOneOne::Funder
    end
    def funder_source
      self.class.funder_source
    end

    def self.health_and_dv_source
      GrdaWarehouse::Export::HMISSixOneOne::HealthAndDv
    end
    def health_and_dv_source
      self.class.health_and_dv_source
    end

    def self.income_benefits_source
      GrdaWarehouse::Export::HMISSixOneOne::IncomeBenefit
    end
    def income_benefits_source
      self.class.income_benefits_source
    end

    def self.inventory_source
      GrdaWarehouse::Export::HMISSixOneOne::Inventory
    end
    def inventory_source
      self.class.inventory_source
    end

    def self.organization_source
      GrdaWarehouse::Export::HMISSixOneOne::Organization
    end
    def organization_source
      self.class.organization_source
    end

    def self.project_source
      GrdaWarehouse::Export::HMISSixOneOne::Project
    end
    def project_source
      self.class.project_source
    end

    def self.project_coc_source
      GrdaWarehouse::Export::HMISSixOneOne::ProjectCoc
    end
    def project_coc_source
      self.class.project_coc_source
    end

    def self.service_source
      GrdaWarehouse::Export::HMISSixOneOne::Service
    end
    def service_source
      self.class.service_source
    end

    def self.geography_source
      GrdaWarehouse::Export::HMISSixOneOne::Geography
    end
    def geography_source
      self.class.geography_source
    end

    def log(message)
      @notifier.ping message if @notifier
      logger.info message if @debug
    end
  end
end
