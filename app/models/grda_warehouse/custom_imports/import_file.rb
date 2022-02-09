###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'rubyXL'
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
      last_start_time = config.import_files.maximum(:started_at).presence || 3.days.ago
      return false unless last_start_time < 23.hours.ago
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
      content_type = ::MimeMagic.by_path(target_path) # Note, these need to be trusted files
      contents = if content_type.to_s.in?(['text/plain', 'text/csv', 'application/csv'])
        ::File.read(target_path)
      else
        CSV.generate do |csv|
          workbook = ::RubyXL::Parser.parse(target_path)
          workbook.worksheets[0].each do |row|
            csv_row = []
            row&.cells&.each do |cell|
              val = cell&.value
              csv_row << val
            end
            csv << csv_row
          end
        end
      end
      sheet = ::Roo::CSV.new(StringIO.new(contents))
      sheet.parse(headers: true).drop(1)

      # store the file in the db for historic purposes
      update(
        file: file,
        content: contents,
        content_type: 'text/csv',
        status: 'loading',
      )
      load_csv(sheet)
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

    def load_csv(file)
      batch_size = 10_000
      loaded_rows = 0

      headers = clean_headers(file.first)
      file.drop(1).each_slice(batch_size) do |lines|
        loaded_rows += lines.count
        rows.klass.import(headers.reject { |h| h == 'do_not_import' }, clean_rows(headers, lines))
      end

      summary << "Loaded #{loaded_rows} rows"
    end

    private def clean_rows(headers, rows)
      # remove any items where the header is nil
      excluded = headers.each_index.select { |i| headers[i] == 'do_not_import' }
      rows.map do |row|
        row = row.delete_if.with_index { |_, i| excluded.include?(i) }
        row + [id, data_source_id]
      end
    end
  end
end
