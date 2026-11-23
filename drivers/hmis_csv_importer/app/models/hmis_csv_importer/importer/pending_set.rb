###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::Importer
  # The warehouse rows an import may soft-delete, held as ids in a session temp
  # table so the warehouse rows themselves are never flagged. Rows are removed
  # as the import accounts for them; whatever remains is soft-deleted.
  #
  # Temp tables belong to one connection, so a set must be used from the
  # connection that created it.
  class PendingSet
    IDENTIFIER_LIMIT = 63

    # Temp tables are session-scoped, but we include a random suffix as a
    # defensive measure against name collisions. The full name is truncated
    # to PostgreSQL's 63-character identifier limit.
    def self.tmp_table_name(prefix, klass)
      suffix = SecureRandom.hex(4) # 8 chars
      base = "tmp_#{prefix}_#{klass.table_name}_"
      "#{base.first(IDENTIFIER_LIMIT - suffix.length)}#{suffix}"
    end

    attr_reader :warehouse_class

    def initialize(warehouse_class)
      @warehouse_class = warehouse_class
      @table_name = self.class.tmp_table_name('pending', warehouse_class)
      @created = false
    end

    # Returns the number of ids newly added. The caller wraps this in
    # disable_nestloop when the scope is a multi-join involved scope.
    def add!(scope)
      create_table!
      connection.execute(<<~SQL).cmd_tuples
        INSERT INTO #{quoted_table} (id)
        SELECT id FROM (#{scope.select(:id).to_sql}) sub
        ON CONFLICT DO NOTHING
      SQL
    end

    # Warehouse rows (soft-deleted included) whose ids are in the set.
    def relation
      return warehouse_class.none unless @created

      base = warehouse_class.paranoid? ? warehouse_class.with_deleted : warehouse_class.all
      base.where("#{warehouse_class.quoted_table_name}.id IN (SELECT id FROM #{quoted_table})")
    end

    # Returns the number of ids removed.
    def remove!(scope)
      return 0 unless @created

      connection.execute(<<~SQL).cmd_tuples
        DELETE FROM #{quoted_table}
        WHERE id IN (SELECT id FROM (#{scope.select(:id).to_sql}) sub)
      SQL
    end

    # Same as remove! for ids already in memory.
    def remove_ids!(ids)
      return 0 unless @created
      return 0 if ids.empty?

      connection.execute(<<~SQL).cmd_tuples
        DELETE FROM #{quoted_table}
        WHERE id IN (#{ids.map { |id| Integer(id) }.join(',')})
      SQL
    end

    # Autovacuum never analyzes temp tables, so callers analyze after the set
    # changes substantially.
    def analyze!
      return unless @created

      connection.execute("ANALYZE #{quoted_table}")
    end

    def drop!
      connection.execute("DROP TABLE IF EXISTS #{quoted_table}")
      @created = false
    end

    private def create_table!
      return if @created

      connection.execute("CREATE TEMP TABLE IF NOT EXISTS #{quoted_table} (id bigint PRIMARY KEY)")
      @created = true
    end

    private def quoted_table
      connection.quote_table_name(@table_name)
    end

    private def connection
      warehouse_class.connection
    end
  end
end
