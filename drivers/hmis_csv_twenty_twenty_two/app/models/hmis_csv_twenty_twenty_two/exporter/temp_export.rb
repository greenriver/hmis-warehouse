###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class TempExport
    # temporary table functionality from https://github.com/zdennis/ar-extensions/blob/master/ar-extensions/lib/ar-extensions/temporary_table.rb
    def self.create_temporary_table(opts = {})
      opts[:table_name] ||= :temp_exports
      opts[:model_name] ||= ActiveSupport::Inflector.classify(opts[:table_name])

      if Object.const_defined?(opts[:model_name])
        puts "Model #{opts[:model_name]} already exists! Refusing to recreate"
        return
      end

      GrdaWarehouseBase.connection.execute <<~SQL
        CREATE SEQUENCE IF NOT EXISTS #{opts[:table_name]}_id_seq;
        CREATE TABLE IF NOT EXISTS
          #{GrdaWarehouseBase.connection.quote_table_name(opts[:table_name])} (
            id int8 NOT NULL DEFAULT nextval('#{opts[:table_name]}_id_seq'::regclass),
            source_id integer,
            PRIMARY KEY ("id")
          );
      SQL

      Object.const_set(
        opts[:model_name],
        Class.new(GrdaWarehouseBase) do
          self.table_name = opts[:table_name]
          def self.drop
            GrdaWarehouseBase.connection.execute "DROP TABLE #{GrdaWarehouseBase.connection.quote_table_name(table_name)};"
            Object.send(:remove_const, name.to_sym)
          end
        end,
      )

      Object.const_get(opts[:model_name])
    end
  end
end
