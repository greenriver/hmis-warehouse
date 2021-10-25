###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::CustomImports
  class ImportFile < GrdaWarehouseBase
    include NotifierConfig

    acts_as_paranoid
    self.table_name = :custom_imports_files
    attr_accessor :notifier_config

    belongs_to :config, class_name: 'GrdaWarehouse::CustomImports::Config'
    has_one :data_source, through: :config

    def check_hour
      return true if Rails.env.development?
      # Only allow imports during the specified hour where it hasn't started in the past 23 hours
      return false unless config.import_files.maximum(:started_at) < 23.hours.ago
      return false unless config.import_hour == Time.current.hour

      true
    end

    def start_import
      setup_notifier('CustomImports')
      update(status: 'started', started_at: Time.current, summary: [])
    end

    def log(message)
      @notifier&.ping(message)
      Rails.logger.info(message)
    end

    def log_summary
      details = summary.join("\n")
      log("Import complete. #{details}")
    end

    def fetch_and_load
      return unless config.s3.present?

      file = most_recent_on_s3
      return unless file

      log("Found #{file}")
      tmp_dir = Rails.root.join('tmp', ::File.dirname(file))
      target_path = ::File.join(tmp_dir, ::File.basename(file))
      FileUtils.mkdir_p(tmp_dir)

      config.s3.fetch(
        file_name: file,
        target_path: target_path.to_s,
      )
      # store the file in the db for historic purposes
      update(
        file: file,
        content: ::File.read(target_path),
        content_type: 'text/csv',
        status: 'loading',
      )
      load_csv(target_path)
      FileUtils.remove_entry(tmp_dir)
    end

    def most_recent_on_s3
      files = []
      # Returns oldest first
      config.s3.fetch_key_list(prefix: config.s3_prefix).each do |entry|
        files << entry if entry.include?(config.s3_prefix)
      end
      return nil if files.empty?

      # Fetch the most recent file
      file = files.last
      return file if file.present?

      nil
    end

    def load_csv(file_path)
      require 'csv'
      batch_size = 10_000
      loaded_rows = 0
      ::File.open(file_path) do |file|
        headers = file.first
        file.lazy.each_slice(batch_size) do |lines|
          csv_rows = CSV.parse(lines.join, headers: headers)
          loaded_rows += csv_rows.count
          rows.klass.import(clean_headers(csv_rows.headers), clean_rows(csv_rows))
        end
      end
      summary << "Loaded #{loaded_rows} rows"
    end

    private def clean_rows(rows)
      rows.map { |row| row.to_h.values + [id, data_source_id] }
    end
  end
end
