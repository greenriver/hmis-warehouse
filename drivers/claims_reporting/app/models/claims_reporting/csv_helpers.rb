# Class to handle upsert style inserts from a CSV (and potentially other flat file formats
# into ClaimsReporting:: models,  They need to define a schema_def class method
require 'csv'
require 'active_support/concern'

module ClaimsReporting::CsvHelpers
  extend ActiveSupport::Concern
  class_methods do
    def reimport_all(path)
      raise "#{path} not found or empty" unless File.size?(path)

      File.open(path) do |f|
        import_csv_data(f, filename: path, replace_all: true)
      end
    end

    # Expects an IO and a String filename for the logs.
    #
    # Returns the number of rows processed.
    def import_csv_data(io, filename:, replace_all:)
      # TODO: Support partial updates by reading rows into tmp table with with_temp_table
      # and then upserting in the final table
      raise 'Partial updates is TODO' unless replace_all

      transaction do
        connection.truncate(table_name) if replace_all
        col_list = csv_cols.join(',')
        log_timing "Loading #{filename} in #{quoted_table_name}" do
          copy_sql = <<~SQL.strip
            COPY #{quoted_table_name} (#{col_list})
            FROM STDIN
            WITH (FORMAT csv,HEADER,QUOTE '"',DELIMITER '|',FORCE_NULL(#{force_null_cols.join(',')}))
          SQL
          # logger.debug { copy_sql }
          pg_conn = connection.raw_connection
          pg_conn.copy_data copy_sql do
            io.each_line do |line|
              pg_conn.put_copy_data(line)
            end
          end
        end
      end
    end

    def schema_data
      @schema_data ||= CSV.parse schema_def, headers: true, converters: lambda { |value, _field_info|
        if value == '-'
          nil
        else
          value
        end
      }
    end

    def csv_cols
      schema_data.map { |r| r['Field name'] }
    end

    def force_null_cols
      schema_data.reject { |r| r['Data type'] == 'string' }.map { |r| r['Field name'] }
    end

    def generate_table_definition
      schema_data.each do |row|
        db_type = row['Data type']
        db_type = 'date' if db_type == 'date (YYYY-MM-DD)'
        puts "t.column '#{row['Field name'].strip}', '#{db_type}', limit: #{db_type == 'string' ? row['Length'] : 'nil'}"
      end
    end

    private def with_temp_table
      tmp_table_name = "mr_#{SecureRandom.hex}"
      log_timing 'Create temp table' do
        connection.create_table(tmp_table_name, id: false, temporary: true) do |t|
          schema_data.each do |row|
            db_type = row['Data type']
            db_type = 'date' if db_type == 'date (YYYY-MM-DD)'
            t.column(
              row['Field name'].strip,
              db_type,
              limit: (row['Length'] if db_type == 'string'),
              # comment: row['Description'],
            )
          end
        end
      end
      yield tmp_table_name
    ensure
      connection.drop_table(tmp_table_name, if_exists: true)
    end

    private def log_timing(str)
      logger.info { "#{self}: #{str} started" }
      res = nil
      bm = Benchmark.measure do
        res = yield
      end
      msg = "#{self}: #{str} completed in #{bm.to_s.strip}"
      logger.info { msg }
      res
    end
  end
end
