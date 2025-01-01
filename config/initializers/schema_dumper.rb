
# needed for Rails < 7.2.2 or main branch prior to this commit:
# https://github.com/rails/rails/commit/d4df3d5f81344ed07187eaced049f1c59d624c34
module SchemaStatementsPartitionAwareness
  def table_options(table_name)
    TodoOrDie('test behavior after rails upgrade', if: Rails.version !~ /\A7\.0/)
    options = {}
    if (comment = table_comment(table_name))
      options[:comment] = comment
    end
    if (partition_definition = table_partition_definition(table_name))
      options[:options] = "PARTITION BY #{partition_definition}"
    end
    options
  end

  def inherited_table?(table_name)
    scope = quoted_scope(table_name, type: "BASE TABLE")

    !!query_value(<<~SQL.squish, "SCHEMA")
      SELECT inhparent::pg_catalog.regclass
      FROM pg_catalog.pg_inherits p
        LEFT JOIN pg_catalog.pg_class c ON p.inhrelid = c.oid
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = #{scope[:name]}
        AND c.relkind IN (#{scope[:type]})
        AND n.nspname = #{scope[:schema]}
    SQL
  end

  def table_partition_definition(table_name)
    scope = quoted_scope(table_name, type: "BASE TABLE")

    query_value(<<~SQL.squish, "SCHEMA")
      SELECT pg_catalog.pg_get_partkeydef(c.oid)
      FROM pg_catalog.pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = #{scope[:name]}
        AND c.relkind IN (#{scope[:type]})
        AND n.nspname = #{scope[:schema]}
    SQL
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.prepend(SchemaStatementsPartitionAwareness)
end


module SchemaDumperExcludeChildPartitions
  def ignored?(table_name)
    super || @connection.inherited_table?(table_name)
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(SchemaDumperExcludeChildPartitions)
end
