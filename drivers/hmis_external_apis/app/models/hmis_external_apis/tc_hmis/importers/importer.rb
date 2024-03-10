###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HmisExternalApis::TcHmis::Importers::Importer.perform(dir: '/host/tc', clobber: true, log_file: '/app/log/tc.log')
module HmisExternalApis::TcHmis::Importers
  class Importer
    include NotifierConfig

    def self.perform(...)
      new(...).perform
    end

    attr_accessor :data_source, :dir, :extra_columns, :clobber, :table_names, :log_file

    def initialize(dir:, clobber: true, log_file: ENV['TC_HMIS_IMPORT_LOG_FILE'])
      self.data_source = HmisExternalApis::TcHmis.data_source
      raise "data source doesn't exist" unless data_source

      self.dir = dir
      raise "directory doesn't exist" unless Dir.exist?(dir)

      self.clobber = clobber
      self.table_names = []
      self.log_file = log_file
    end

    def perform
      start
      loaders = [
        Loaders::SpdatLoader,
        Loaders::HatLoader,
        Loaders::UhaLoader,
        Loaders::CustomServicesLoader,
        Loaders::CriticalDocumentsCmLoader,
        Loaders::CaseManagementAssessmentLoader,
        Loaders::MhmrCaseManagementNoteLoader,
        Loaders::MhmrNonBillableNoteLoader,
        Loaders::MhmrRehabilitationNoteLoader,
        Loaders::CustomClientDemographicsLoader,
        Loaders::NavigationNotesLoader,
        Loaders::DiversionAssessmentLoader,
        # This importer was not needed
        # Loaders::EhvApplicationLoader,
      ]

      # disable paper trail to improve importer performance
      PaperTrail.enabled = false
      loaders.each do |loader_class|
        loader = loader_class.new(
          clobber: clobber,
          reader: Loaders::FileReader.new(dir),
          log_file: log_file,
        )
        run_loader(loader)
        GC.start
      end

      analyze_tables
      true
    rescue StandardError => e
      # this might be swallowing the exception
      @notifier.ping("Failure in #{importer_name}") # , { exception: e })
      raise e
    end

    protected

    def run_loader(loader)
      # skip loaders that have no data files in the archive
      unless loader.runnable?
        Rails.logger.info "#{importer_name} skipping #{loader.class.name}"
        return
      end

      Rails.logger.info "#{importer_name} running #{loader.class.name}"
      loader.perform
      self.table_names += loader.table_names
    end

    def importer_name
      self.class.name
    end

    def start
      setup_notifier(importer_name)
      Rails.logger.info "Starting #{importer_name}"
    end

    def analyze_tables
      # assume all tables are in same db
      connection = Hmis::Hud::Base.connection
      Rails.logger.info 'Analyzing imported tables'
      names = table_names.uniq.map { |n| connection.quote_table_name(n) }
      connection.exec_query("ANALYZE #{names.join(',')};")
    end
  end
end
