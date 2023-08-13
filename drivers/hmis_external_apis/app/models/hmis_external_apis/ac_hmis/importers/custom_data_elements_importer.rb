###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers
  class CustomDataElementsImporter
    include NotifierConfig

    AbortImportException = Class.new(StandardError)

    attr_accessor :attempt
    attr_accessor :data_source
    attr_accessor :dir
    attr_accessor :extra_columns

    def initialize(dir:, key:, etag:)
      self.attempt = ProjectsImportAttempt.where(etag: etag, key: key).first_or_initialize
      self.data_source = HmisExternalApis::AcHmis.data_source
      self.dir = dir
    end

    def run!
      start
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

      table_names = []
      clobber = true
      ProjectsImportAttempt.transaction do
        loaders.each do |loader_class|
          loader = loader_class.new(
            reader: Loaders::CsvReader.new(dir),
            clobber: clobber,
          )
          # skip loaders that have no data files in the archive
          next unless loader.data_file_provided?

          result = loader.perform
          handle_import_result(result)
          table_names += loader.table_names
        end
      end
      analyze(table_names.uniq)
      finish
    rescue AbortImportException => e
      @notifier.ping("Failure in #{importer_name}", { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal "#{importer_name} Aborted before it finished."
    end

    protected

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
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def analyze(table_names)
      # assume all tables are in same db
      Rails.logger.info 'Analyzing imported tables'
      names = table_names.map { |n| connection.quote_table_name(n) }
      connection.exec_query("ANALYZE #{names.join(',')};")
    end

    def connection
      ProjectsImportAttempt.connection
    end

    def finish
      attempt.status = ProjectsImportAttempt::SUCCEEDED
      attempt.save!
    end

    def records_from_csv(file)
      io = File.open(file, 'r')

      # Checking for BOM
      if io.read(3).bytes == [239, 187, 191]
        Rails.logger.info 'Byte-order marker (BOM) found. Skipping it.'
      else
        io.rewind
      end

      CSV.parse(io.read, **csv_config)
    end

    def csv_config
      {
        headers: true,
        skip_lines: /\A\s*\z/,
      }
    end

    def sys_user
      @sys_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end
  end
end
