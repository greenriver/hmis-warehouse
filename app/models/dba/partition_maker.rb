# https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE

class DBA::PartitionMaker
  attr_accessor :base_class
  attr_accessor :klass
  attr_accessor :num_partitions
  attr_accessor :old_table
  attr_accessor :partition_column
  attr_accessor :partitioned_table
  attr_accessor :schema

  # Create a normal, non-partitioned table/model first, and pass in the table name
  # schema is where we'll "hide" all the partitions
  def initialize(num_partitions: 71, partition_column: nil, schema: 'hmis', table_name:)
    self.klass = klass
    self.num_partitions = num_partitions
    self.old_table = "#{table_name}_saved"
    self.partitioned_table = table_name
    self.base_class = GrdaWarehouseBase
    self.schema = schema
    self.partition_column = partition_column

    if table_exists?(partitioned_table)
      self.partition_column ||= _default_column
    end
  end

  def start_over!
    _trash_it_all
  end

  def run!
    _schema
    _main_table
    _make_partitions
    _copy
  end

  def done?
    table_exists?(old_table)
  end

  def no_table?
    !table_exists?(partitioned_table)
  end

  private

  def _schema
    p(<<~SQL)
      CREATE SCHEMA IF NOT EXISTS "#{schema}";
    SQL
  end

  def _main_table
    return if table_exists?(old_table)

    base_class.transaction do
      # backup the non-partitioned table
      p(<<~SQL)
        ALTER TABLE "#{partitioned_table}" RENAME TO "#{old_table}";
      SQL

      temp = "#{partitioned_table}_temp"

      p(<<~SQL)
        DROP TABLE IF EXISTS "#{temp}"
      SQL

      # Build out a table with the same shape, but with the partition column
      # added to all unique indexes/constraints. ActiveRecord may need
      # adjustments to understand the primary key is really just the ID.
      p(<<~SQL)
        CREATE TABLE "#{temp}" (LIKE "#{old_table}" INCLUDING ALL)
      SQL

      p(<<~SQL)
        ALTER TABLE "#{temp}" DROP CONSTRAINT "#{temp}_pkey"
      SQL

      p(<<~SQL)
        ALTER TABLE "#{temp}" ADD PRIMARY KEY (id, "#{partition_column}")
      SQL

      unique_indexes(temp).each do |row|
        p(<<~SQL)
          DROP INDEX "#{row['index_name']}"
        SQL

        new_def = row['indexdef'].sub(')', ", \"#{partition_column}\")")
        p new_def
      end

      p(<<~SQL)
        CREATE TABLE "#{partitioned_table}" (LIKE "#{temp}" INCLUDING ALL)
          PARTITION BY HASH ("#{partition_column}")
      SQL

      p(<<~SQL)
        DROP TABLE "#{temp}"
      SQL
    end
  end

  def _make_partitions
    0.upto(num_partitions - 1).each do |partnum|
      _make_one_partition(partnum)
    end
  end

  def _copy
    results = Benchmark.measure do
      p(<<~SQL)
        INSERT INTO "#{partitioned_table}" SELECT * FROM "#{old_table}"
      SQL
    end
    Rails.logger.info "Copy of #{partitioned_table} to partitioned version took #{results.real} seconds"
  end

  def _make_one_partition(partnum)
    p(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{schema}.#{partitioned_table}_#{partnum}
        PARTITION OF #{partitioned_table}
        FOR VALUES WITH ( MODULUS #{num_partitions}, REMAINDER #{partnum} )
    SQL
  end

  def _trash_it_all
    return unless Rails.env.development?

    # Just checking if the table is there.
    return unless table_has_column?(old_table, 'id')

    p "DROP TABLE IF EXISTS #{partitioned_table}"

    p "ALTER TABLE IF EXISTS #{old_table} RENAME TO #{partitioned_table}"

  end

  def _compare
    [partitioned_table, old_table].each do |schema|
      p(<<~SQL)
        EXPLAIN (ANALZYE, BUFFERS, COSTS, VERBOSE)
        select * from ...
      SQL
    end
  end

  def p(str, logit: true)
    Rails.logger.info(str) if logit
    base_class.connection.exec_query(str)
  end

  def table_exists?(name)
    base_class.connection.table_exists?(name)
  end

  def table_has_column?(table_name, column_name)
    r = p(<<~SQL, logit: false)
      SELECT count(*) AS num
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = '#{table_name}'
      AND column_name = '#{column_name}'
    SQL
    r.first['num'] == 1
  end

  def unique_indexes(table_name)
    p(<<~SQL, logit: false)
      SELECT a.indexrelid, a.relname, a.indexrelname AS "index_name", c.indexdef
      FROM
        pg_stat_user_indexes a
        JOIN pg_index b ON (b.indexrelid = a.indexrelid)
        JOIN pg_indexes c ON ( c.indexname = a.indexrelname )
      WHERE
        relname = '#{table_name}'
        AND b.indisunique
        AND indexrelname not like '%_pkey'
    SQL
  end

  def _default_column
    if table_has_column?(partitioned_table, 'importer_log_id')
      'importer_log_id'
    elsif table_has_column?(partitioned_table, 'loader_id')
      'loader_id'
    else
      raise 'could not figure out default partitioning column'
    end
  end
end
