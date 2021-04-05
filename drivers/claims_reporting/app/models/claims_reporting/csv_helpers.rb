# Class to handle upsert style inserts from a CSV (and potentially other flat file formats
# into ClaimsReporting:: models.

# Each model class needs to define a self.schema_def method. See existing definitions for examples
# Each model class needs to define a self.conflict_target method that list the columns
# that form a unique key for a row within the data.
#
# This concern will then implement #import_csv_data in a way that uses
# postgres COPY ... FROM, temp tables and INSERT INTO .. ON CONFLICT to bulk
# load the data very efficiently, bypassing active_record models and
# using streaming APIs for postgres where possible.

require 'csv'
require 'active_support/concern'

module ClaimsReporting::CsvHelpers
  extend ActiveSupport::Concern
  class_methods do
    # Expects an IO and a String filename for the logs.
    #
    # Returns a hash with stats
    # {
    #   filename: filename,
    #   replace_all: replace_all,
    #   lines_read: ...,
    #   records_read: ...,
    #   records_upserted: ...,
    #   ...
    # }
    def import_csv_data(io, filename:, replace_all:)
      res = {
        filename: filename,
        replace_all: replace_all,
      }
      bm = log_timing "import_csv_data(#{filename}, replace_all: #{replace_all}" do
        transaction do
          if replace_all
            # skip the temp table
            connection.truncate(table_name)
            res.merge! copy_data_into io, filename, table_name # go right in the model table
          else
            with_temp_table(table_name) do |tmp_table_name|
              res.merge! copy_data_into io, filename, tmp_table_name
              res.merge! upsert_from tmp_table_name
            end
          end
        end
        # we potentially changed a large percentage of the data in this table
        connection.execute("VACUUM (ANALYZE) #{quoted_table_name}") if connection.open_transactions.zero?
      end
      res[:bm] = bm.to_a
      res[:elapsed_seconds] = bm.real
      res[:cpu_seconds] = bm.total
      res[:rps] = res[:records_read].to_f / bm.real
      res
    end

    # Returns a hash with counts
    # {
    #   lines_read: lines_read,
    #   records_updated: records_updated,
    # }
    private def copy_data_into(io, filename, table_name)
      raise "#{self}.upsert_from doesn't define any csv_cols (via schema_def?)" unless respond_to?(:csv_cols) && csv_cols.any?

      lines_read = 0
      records_read = nil
      actual_cols = CSV.parse_line(io, col_sep: '|')
      extra_cols = actual_cols - csv_cols
      raise "#{filename} contains unexpected columns: #{extra_cols}" if extra_cols.any?

      col_list = actual_cols.join(',')
      log_timing "copy_data_into(#{filename}) => #{table_name}" do
        # the claims data is actually quoted pipe delimited

        copy_sql = <<~SQL.strip
          COPY #{table_name} (#{col_list})
          FROM STDIN
          WITH (FORMAT csv,HEADER,QUOTE '"',DELIMITER '|',FORCE_NULL(#{force_null_cols.join(',')}))
        SQL
        # logger.debug { copy_sql }
        pg_conn = connection.raw_connection
        pg_result = pg_conn.copy_data copy_sql do
          io.each_line do |line|
            lines_read += 1
            pg_conn.put_copy_data(line.encode!('UTF-8', 'UTF-8', undef: :replace, invalid: :replace))
          end
        end
        records_read = pg_result.cmd_tuples
        pg_result.clear
      end
      {
        lines_read: lines_read,
        records_read: records_read,
      }
    end

    # returns a Hash of stats
    private def upsert_from(tmp_table_name)
      raise "#{self}.upsert_from doesn't define upsert conflict_target info" unless respond_to?(:conflict_target) && conflict_target.any?

      results = {}
      log_timing "upsert_from(#{tmp_table_name}) => #{table_name}" do
        col_sep = ",\n"
        col_list = csv_cols.join(col_sep)
        updates = (csv_cols - conflict_target).map do |col|
          quote_col = connection.quote_column_name(col)
          "#{quote_col}=excluded.#{quote_col}"
        end
        sql = <<~SQL
          INSERT INTO #{quoted_table_name} (#{col_list})
          SELECT \n#{col_list} \nFROM #{connection.quote_table_name tmp_table_name}
          ON CONFLICT (#{conflict_target.join(',')})
          DO UPDATE SET #{updates.join(col_sep)}
        SQL
        begin
          pg_result = connection.execute sql
          logger.info { "#{self}.upsert_from(#{tmp_table_name}) result #{pg_result}" }
          results[:records_upserted] = pg_result.cmd_tuples
          pg_result.clear
        rescue PG::Error => e
          logger.error { "#{self}.upsert_from(#{tmp_table_name}) failed #{e.inspect}" }
          raise
        end
      end
      results
    end

    # The CSV schema as an array of hashes
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
      schema_data.map { |r| r['Field name'].strip }
    end

    private def force_null_cols
      schema_data.reject { |r| r['Data type'] == 'string' }.map { |r| r['Field name'] }
    end

    # writes out some ruby code to define the table based on schema_data
    def generate_table_definition
      schema_data.each do |row|
        db_type = row['Data type']
        db_type = 'date' if db_type == 'date (YYYY-MM-DD)'
        puts "t.column '#{row['Field name'].strip}', '#{db_type}', limit: #{db_type == 'string' ? row['Length'] : 'nil'}"
      end
    end

    private def with_temp_table(base_name)
      tmp_table_name = "#{base_name}_#{SecureRandom.hex}"
      log_timing "with_temp_table(#{base_name})" do
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
      bm = Benchmark.measure(str) do
        res = yield
      end
    ensure
      msg = "#{self}: #{str} finished in #{bm.to_s.strip}"
      logger.info { msg }
      res
    end
  end
end
