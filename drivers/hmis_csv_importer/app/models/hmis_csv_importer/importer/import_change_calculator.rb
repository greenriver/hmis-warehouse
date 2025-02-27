module HmisCsvImporter::Importer
  class ImportChangeCalculator
    def self.apply(...) = new.apply(...)

    # Calculate changes for a single file/class combination
    # @param klass [Class] The class representing the data model
    # @param existing_scope [ActiveRecord::Relation] The scope for existing data
    # @param incoming_scope [ActiveRecord::Relation] The scope for incoming data
    # @return [Hash] Hash containing counts of records to add and remove
    def apply(klass:, existing_scope:, incoming_scope:)
      results = {}
      return results unless klass.respond_to?(:hud_key)

      @connection = klass.connection
      temp_table_name = nil
      begin
        # Create temp table for incoming data
        temp_table_name = create_temp_table(klass, incoming_scope)

        # Calculate additions and removals
        results['added'] = count_additions(klass, existing_scope, temp_table_name)
        results['removed'] = count_removals(klass, existing_scope, temp_table_name)
      ensure
        # Clean up temp table even if an error occurs
        drop_temp_table(temp_table_name)
      end
      results
    end

    private

    # Create a temporary table with incoming data
    def create_temp_table(klass, incoming_scope)
      # Generate unique table name
      temp_table_name = "temp_incoming_#{Time.current.to_i}_#{rand(1000)}"
      hud_key = klass.hud_key

      # Create the table and insert values
      @connection.execute("CREATE TEMPORARY TABLE #{qtn temp_table_name} (#{qcn hud_key} character varying NOT NULL)")
      @connection.execute(<<-SQL)
        INSERT INTO #{qtn temp_table_name} (#{qcn hud_key})
        SELECT #{qcn hud_key}
        FROM (#{incoming_scope.select(hud_key).to_sql}) AS subquery
      SQL

      # Add index for performance
      @connection.execute("CREATE INDEX #{qcn "idx_#{temp_table_name}"} ON #{qtn temp_table_name} (#{qcn hud_key})")

      temp_table_name
    end

    # Count records to be added (in incoming but not in existing)
    def count_additions(klass, existing_scope, temp_table_name)
      hud_key = klass.hud_key
      sql = <<-SQL
        SELECT COUNT(*)
        FROM #{qtn temp_table_name} AS incoming
        WHERE NOT EXISTS (
          SELECT 1
          FROM (#{existing_scope.select(hud_key).to_sql}) AS existing_data
          WHERE existing_data.#{qcn hud_key} = incoming.#{qcn hud_key}
        )
      SQL
      @connection.select_value(sql)&.to_i
    end

    # Count records to be removed (in existing but not in incoming)
    def count_removals(klass, existing_scope, temp_table_name)
      return 0 if klass.respond_to?(:prevent_import_deletions?) && klass.prevent_import_deletions?

      hud_key = klass.hud_key

      existing_scope.
        joins("LEFT JOIN #{qtn temp_table_name} ON #{qtn existing_scope.table.name}.#{qcn hud_key} = #{qtn temp_table_name}.#{qcn hud_key}").
        where("#{qtn temp_table_name}.#{qcn hud_key} IS NULL").
        count
    end

    # Drop the temporary table
    def drop_temp_table(temp_table_name)
      @connection.execute("DROP TABLE IF EXISTS #{qtn temp_table_name}")
    end

    def qtn(str)
      @connection.quote_table_name(str)
    end

    def qcn(str)
      @connection.quote_column_name(str)
    end
  end
end
