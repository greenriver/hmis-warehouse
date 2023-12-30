###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ShHmis::Importers
  class CustomDataElementsImporter
    include NotifierConfig

    attr_accessor :data_source, :dir, :extra_columns, :clobber, :table_names

    def initialize(dir:, clobber:)
      self.data_source = HmisExternalApis::AcHmis.data_source
      self.dir = dir
      self.clobber = clobber
      self.table_names = []
    end

    def run!
      start

      loaders = [
        Loaders::ClientZipcodesLoader,
        Loaders::CurrentLivingSituationNoteLoader,
        Loaders::FlexFundsLoader,
        Loaders::YouthEducationStatusLoader,
        Loaders::CaseNotesLoader,
      ]

      # disable paper trail to improve importer performance
      PaperTrail.enabled = false
      loaders.each do |loader_class|
        loader = loader_class.new(
          clobber: clobber,
          reader: Loaders::CsvReader.new(dir),
        )
        run_loader(loader)
      end

      analyze_tables
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
