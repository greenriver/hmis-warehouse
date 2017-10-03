require 'zip'
require 'csv'
module Exporters::HmisSixOneOne
  class Base
    include NotifierConfig
    include ArelHelper
    
    attr_accessor :logger, :notifier_config

    def initialize(
      file_path: 'var/hmis_export',
      logger: Rails.logger, 
      debug: true,
      range:,
      projects:,
      period_type: 3,
      directive: 3,
      hash_status: 1,
      faked_pii: false,
      include_deleted: false,
      faked_environment: :development
    )
      setup_notifier('HMIS Exporter 6.11')
      @file_path = "#{file_path}/#{Time.now.to_i}"
      @logger = logger
      @debug = debug
      @range = range
      @projects = projects
      @period_type = period_type
      @directive = directive
      @hash_status = hash_status     
      @faked_pii = faked_pii
      @user = current_user rescue nil
      @include_deleted = include_deleted
      @faked_environment = faked_environment
    end

    def export!
      create_export_directory()
      begin
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
      ensure
        remove_export_files()
      end
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
      project_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_project_cocs
      project_coc_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_organizations
      organization_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_inventories
      inventory_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_geographies
      geography_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_funders
      funder_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_affiliations
      affiliation_source.export!(
        project_scope: project_scope, 
        path: @file_path, 
        export: @export
      )
    end

    def export_enrollments
      enrollment_source.export!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_enrollment_cocs
      enrollment_coc_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_clients
      client_source.export!(
        enrollment_scope: enrollment_scope,
        client_scope: client_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_disabilities
      disability_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_employment_educations
      employment_education_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_exits
      exit_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_health_and_dvs
      health_and_dv_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_income_benefits
      income_benefits_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def export_services
      service_source.export_enrollment_related!(
        enrollment_scope: enrollment_scope,
        project_scope: project_scope,
        path: @file_path, 
        export: @export
      )
    end

    def enrollment_scope
      @enrollment_scope ||= begin
        # Choose all enrollments opened before the end of the report period in the involived projects for clients who had an open enrollmentduring the report period.
        if @export.include_deleted
          enrollment_source.joins(:project_with_deleted, :client_with_deleted).
            where(Client: {id: client_scope.select(c_t[:id])}).
            merge(project_scope).
            where(e_t[:EntryDate].lteq(@range.start))
          
        else
          enrollment_source.joins(:project, :client).
            where(Client: {id: client_scope.select(c_t[:id])}).
            merge(project_scope).
            where(e_t[:EntryDate].lteq(@range.start))
        end
      end
    end

    def client_scope
      # include any client with an open enrollment
      # during the report period in one of the involved projects
      @client_scope ||= begin
        if @export.include_deleted
        enrollment_source.joins(:project_with_deleted, :client_with_deleted).
          merge(project_scope).
          open_during_range(@range)
        else
          enrollment_source.joins(:project, :client).
            merge(project_scope).
            open_during_range(@range)
        end
      end
    end

    def project_scope
      @project_scope ||= begin
       project_scope = project_source.where(id: @projects)
        if @export.include_deleted
          project_scope = project_scope.with_deleted
        end
        project_scope
      end      
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

      @export = GrdaWarehouse::Export.where(export_id: options[:export_id]).first_or_create(options)
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
      export.ExportDate = Date.today
      export.ExportStartDate = @range.start
      export.ExportEndDate = @range.end
      export.SoftwareName = 'Boston HMIS Warehouse'
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