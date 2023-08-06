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
      items = [
        [EsgFundingAssistanceLoader, 'ESGFundingAssistance.csv'],
        [EmergencyShelterAllowanceGrantLoader, 'EmergencyShelterAllowanceGrant.csv'],
      ]
      check_file_names(items.map&:last)

      items.each do |loader, filename|
        rows = records_from_csv(file_name)
        loader.validate(rows)
      end

      table_names = []
      ProjectsImportAttempt.transaction do
        items.each do |loader, filename|
          rows = records_from_csv(file_name)
          result = loader.perform(rows: rows)
          handle_import_result(result)
          table_names += loader.table_names
        end
      end
      analyze(table_names)
      finish
    rescue AbortImportException => e
      @notifier.ping("Failure in #{importer_name}", { exception: e })
      Rails.logger.fatal e.message
      Rails.logger.fatal "#{importer_name} Aborted before it finished."
    end

    protected

    def run_loader(loader, file_name)
      EsgFundingAssistanceLoader
        .perform(rows: records_from_csv('ESGFundingAssistance.csv'))
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
      Rails.logger.info "Starting #{attempt.key}"
      attempt.attempted_at = Time.current
      attempt.status = ProjectsImportAttempt::STARTED
      attempt.save!
    end

    def check_file_names(file_names)
      file_names.each do |fn|
        msg << "#{fn} was not present." unless File.exist?("#{dir}/#{fn}")
      end
      return unless msg.present?

      msg = msg.join('. ')

      Rails.logger.error(msg)
      attempt.attempted_at = Time.now
      attempt.status = ProjectsImportAttempt::FAILED
      attempt.result = { error: msg }
      attempt.save!
      raise AbortImportException, msg
    end

    def analyze(table_names)
      # assume all tables are in same db
      Rails.logger.info 'Analyzing imported tables'
      names = table_names.map(connection.quote_table_name(names))
      ProjectsImportAttempt.connection.exec_query('ANALYZE "Funder", "Project", "Organization", "CustomDataElements";')
    end

    def connection
      ProjectsImportAttempt.connection
    end

    def finish
      attempt.status = ProjectsImportAttempt::SUCCEEDED
      attempt.save!
    end

    def check_columns(file:, expected_columns:, critical_columns:, rows:)
      raise AbortImportException, "There was no data in #{file}." if rows.empty?

      keys = rows.first.to_h.keys

      missing_columns = expected_columns - keys
      missing_critical_columns = critical_columns - keys

      self.extra_columns = keys - expected_columns

      Rails.logger.warn("Skipping extra columns (#{extra_columns.join(', ')}) in #{file}") if extra_columns.present?

      raise(AbortImportException, "There were critical missing columns in #{file}: #{missing_critical_columns.join(', ')}.") if missing_critical_columns.present?

      Rails.logger.warn("There were non-critical missing columns in #{file}: #{missing_columns.join(', ')}.") if missing_columns.present?
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
