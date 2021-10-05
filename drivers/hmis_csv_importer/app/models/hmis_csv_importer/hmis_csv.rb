###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsv
  extend ActiveSupport::Concern
  included do
    def self.loadable_files
      importable_files_map.transform_values do |name|
        data_lake_file_class(name, 'Loader')
      end
    end

    def self.importable_files
      importable_files_map.transform_values do |name|
        data_lake_file_class(name, 'Importer')
      end
    end

    def self.importable_file_class(name)
      importable_files["#{name}.csv"]
    end

    def self.importable_files_map
      Rails.application.config.hmis_data_lake.constantize.importable_files_map
    end

    def self.data_lake_file_class(name, phase)
      "#{Rails.application.config.hmis_data_lake}::#{phase}::#{name}".constantize
    end

    def log(message, attachment = nil)
      logger.info message
      if attachment.present?
        @notifier&.post(text: message, attachments: { text: attachment })
      else
        @notifier&.ping(message)
      end
    end

    def summary_as_log_str(summary)
      cols = summary.values.flat_map(&:keys).uniq
      cols -= ['pp_rps', 'add_rps', 'up_rps']
      headers = cols.map do |col|
        col.gsub('pre_processed', 'pre').
          gsub('total_errors', 'errors').
          gsub('total_flags', 'flags').
          gsub('unchanged', 'un').
          gsub('updated', 'up')
      end
      table = [
        ['File'] + headers,
      ]
      summary.each do |file, info|
        table << [file] + info.values_at(*cols)
      end
      "\n```\n#{ANSI::Table.new table}\n```\n"
    end

    def hash_as_log_str(hash, field_sep: ' ')
      hash.map do |k, v|
        " #{k}: #{v}"
      end.join(field_sep)
    end

    def elapsed_time(total_seconds)
      d = total_seconds / 86_400
      h = total_seconds / 3600 % 24
      m = total_seconds / 60 % 60
      s = total_seconds % 60
      if d >= 1
        format('%id%ih%im%.3fs', d, h, m, s)
      elsif h >= 1
        format('%ih%im%.3fs', h, m, s)
      elsif m >= 1
        format('%im%.3fs', m, s)
      else
        format('%.3fs', s)
      end
    end

    def log_timing(message)
      logger.debug { "#{message} #{hash_as_log_str log_ids}" }
      ret = nil
      bm = Benchmark.measure do
        ret = send(message)
      end

      log "#{message} completed in #{elapsed_time bm.real} (#{(bm.total * 100.0 / bm.real).round}% cpu) #{hash_as_log_str log_ids}"
      ret
    end
  end
end
