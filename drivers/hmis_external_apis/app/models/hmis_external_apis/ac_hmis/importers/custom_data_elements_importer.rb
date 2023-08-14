###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class CustomDataElementsImporter
    include NotifierConfig

    AbortImportException = Class.new(StandardError)

    attr_accessor :data_source, :dir, :extra_columns, :clobber, table_names

    def initialize(dir:, clobber:)
      self.data_source = HmisExternalApis::AcHmis.data_source
      self.dir = dir
      self.clobber = clobber
      self.table_names = []
    end

    def run!
      start
      tracker = Loaders::ProjectUnitTracker.new(data_source)
      loaders = [
        Loaders::EmergencyShelterAllowanceGrantLoader, # -> 'EmergencyShelterAllowanceGrant.csv'
        Loaders::EsgFundingAssistanceLoader, # 'ESGFundingAssistance.csv'
        Loaders::FederalPovertyLevelLoader, # 'FederalPovertyLevel.csv'
        Loaders::ReasonForExitLoader, # 'ReasonForExit.csv'
        Loaders::RentalAssistanceEndDateLoader, # 'RentalAssistanceEndDate.csv'
        Loaders::WalkInEnrollmentUnitTypesLoader, # 'WalkInEnrollmentUnitTypes.csv'
        Loaders::ClientAddressLoader, # 'ClientAddress.csv'
        Loaders::ClientContactsLoader, # 'ClientContacts.csv'
        Loaders::ReferralPostingsLoader, # needs to run after WalkInEnrollmentUnitTypesLoader to avoid deleting UnitOccupancy
        Loaders::ReferralRequestsLoader, # needs to run after ReferralPostingsLoader to reference referralIDs
      ]

      ProjectsImportAttempt.transaction do
        loaders.each do |loader_class|
          loader = loader_class.new(
            clobber: clobber,
            reader: Loaders::CsvReader.new(dir),
            tracker: tracker
          )
          run_loader(loader)
        end

        run_loader(
          Loaders::DerivedProjectUnitOccupancyLoader.new(clobber: clobber, tracker: tracker)
        )
      end

      analyze_tables
    rescue AbortImportException => e
      @notifier.ping("Failure in #{importer_name}", { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal "#{importer_name} Aborted before it finished."
    end

    protected

    def run_loader(loader)
      # skip loaders that have no data files in the archive
      next unless loader.data_file_provided?

      result = loader.perform
      handle_import_result(result)
      table_names += loader.table_names
    end

    def handle_import_result(result)
      return unless result.failed_instances.present?

      msg = "Failed: #{result.failed_instances}. Aborting"
      raise AbortImportException, msg
    end

    def importer_name
      self.class.name
    end

    def start
      setup_notifier(importer_name)
      Rails.logger.info "Starting #{importer_name}"
    end

    def analyze
      # assume all tables are in same db
      Rails.logger.info 'Analyzing imported tables'
      names = table_names.uniq.map { |n| connection.quote_table_name(n) }
      connection.exec_query("ANALYZE #{names.join(',')};")
    end

    def connection
      ProjectsImportAttempt.connection
    end
  end
end
