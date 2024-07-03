###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter
  class TempTable
    # temporary table functionality from https://github.com/zdennis/ar-extensions/blob/master/ar-extensions/lib/ar-extensions/temporary_table.rb
    def self.create_temporary_table(table_name:, model_name:)
      if Object.const_defined?(model_name)
        puts "Model #{model_name} already exists! Refusing to recreate"
        return
      end

      GrdaWarehouseBase.connection.execute <<~SQL
        CREATE SEQUENCE IF NOT EXISTS #{table_name}_id_seq;
        CREATE TABLE IF NOT EXISTS
          #{GrdaWarehouseBase.connection.quote_table_name(table_name)} (
            id int8 NOT NULL DEFAULT nextval('#{table_name}_id_seq'::regclass),
            source_id integer,
            batch_id integer,
            PRIMARY KEY ("id")
          );
        CREATE INDEX #{table_name}_batch_id ON batch_id;
      SQL

      Object.const_set(
        model_name,
        Class.new(GrdaWarehouseBase) do
          self.table_name = table_name
          def self.drop
            GrdaWarehouseBase.connection.execute "DROP TABLE #{GrdaWarehouseBase.connection.quote_table_name(table_name)};"
            GrdaWarehouseBase.connection.execute "DROP SEQUENCE IF EXISTS \"#{table_name}_id_seq\";"
            Object.send(:remove_const, name.to_sym)
          end
        end,
      )

      Object.const_get(model_name)
    end
  end
end
