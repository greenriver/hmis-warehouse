require 'zip'
require 'csv'
module Exporters::HmisSixOneOne
  class Base
    include NotifierConfig
    
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
      include_deleted: false
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
    end

    def export!
      create_export_directory()
      setup_export()
      
      export_projects()
      build_export_file()
    end

    def export_projects
      project_source.export!(project_scope: project_scope, path: @file_path, export: @export)
    end

    def project_scope
      project_source.where(id: @projects)
    end

    def setup_export
      @export = GrdaWarehouse::Export.new()
      @export.user_id = @user&.id
      @export.start_date = @range.start
      @export.end_date = @range.end
      @export.period_type = @period_type
      @export.directive = @directive
      @export.hash_status = @hash_status
      @export.faked_pii = @faked_pii
      @export.project_ids = @projects
      @export.include_deleted = @include_deleted
      # a hash of attributes
      @export.export_id = Digest::MD5.hexdigest(@export.attributes.to_s)
      @export.save
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