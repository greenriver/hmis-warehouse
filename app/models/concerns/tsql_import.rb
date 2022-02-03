###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TsqlImport
  extend ActiveSupport::Concern
  included do
    def batch_insert_template(klass, columns)
      @batch_insert_template = begin
        tn = klass.quoted_table_name
        cols = columns.map { |c| klass.connection.quote_column_name c }.join(',')
        "INSERT INTO #{tn} (#{cols}) VALUES "
      end
    end

    def insert_batch(klass, columns, values, transaction: true, batch_size: 200)
      return if values.empty?

      if transaction
        klass.transaction do
          process klass, columns, values, batch_size: batch_size
        end
      else
        process klass, columns, values, batch_size: batch_size
      end
    end

    def process(klass, columns, values, batch_size: 200)
      cmd = batch_insert_template(klass, columns).to_s
      # tsql limits bulk inserts to 1000 rows
      values.each_slice(batch_size) do |a|
        values_sql = a.map do |row|
          quoted_values = row.map { |val| klass.connection.quote(val) }
          "(#{quoted_values.join(',')})"
        end.join(',')
        klass.benchmark "#{klass}#insert_batch: #{a.size} rows" do
          klass.logger.silence do
            sql = "#{cmd} #{values_sql}"
            klass.connection.execute sql
          end
        end
      end
    end
  end
end
