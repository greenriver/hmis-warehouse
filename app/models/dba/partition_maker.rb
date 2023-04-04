###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE

class Dba::PartitionMaker
  attr_accessor :base_class
  attr_accessor :klass
  attr_accessor :num_partitions
  attr_accessor :old_table
  attr_accessor :partition_column
  attr_accessor :partitioned_table
  attr_accessor :schema
  attr_accessor :table_name

  # Create a normal, non-partitioned table/model first, and pass in the table name
  # schema is where we'll "hide" all the partitions
  def initialize(num_partitions: 71, partition_column: nil, schema: 'hmis', table_name:)
    self.klass = klass
    self.num_partitions = num_partitions
    self.old_table = "#{table_name}_saved"
    self.partitioned_table = "#{table_name}_partitioned"
    self.table_name = table_name
    self.base_class = GrdaWarehouseBase
    self.schema = schema
    self.partition_column = partition_column

    return unless table_exists?(table_name)

    self.partition_column ||= _default_column
  end

  def start_over!
    _trash_it_all
  end

  def run!
    _schema
    _make_table_and_partitions_transactionally
    _switch_them
  end

  def done?
    result = p(<<~SQL)
      SELECT relkind
      FROM pg_class
      WHERE relname = '#{table_name}'
    SQL

    # The table is a partitioned table and the transactional insert/renaming
    # happened. It can't have been renamed without copying the data
    result[0]['relkind'] == 'p' && !table_exists?(partitioned_table)
  end

  def no_table?
    !table_exists?(table_name)
  end

  private

  def _schema
    p(<<~SQL)
      CREATE SCHEMA IF NOT EXISTS "#{schema}";
    SQL
  end

  def _make_table_and_partitions_transactionally
    return if table_exists?(old_table)
    return if table_exists?(partitioned_table)

    base_class.transaction do
      temp = "#{partitioned_table}_temp"

      p(<<~SQL)
        DROP TABLE IF EXISTS "#{temp}"
      SQL

      # Build out a table with the same shape, but with the partition column
      # added to all unique indexes/constraints. ActiveRecord may need
      # adjustments to understand the primary key is really just the ID.
      p(<<~SQL)
        CREATE TABLE "#{temp}" (LIKE "#{table_name}" INCLUDING ALL)
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

      _make_partitions

      p(<<~SQL)
        DROP TABLE "#{temp}"
      SQL

      _copy
    end
  end

  def _switch_them
    base_class.transaction do
      # backup the non-partitioned table
      p(<<~SQL)
        ALTER TABLE "#{table_name}" RENAME TO "#{old_table}";
      SQL

      p(<<~SQL)
        ALTER TABLE "#{partitioned_table}" RENAME TO "#{table_name}";
      SQL

      p(<<~SQL)
        ALTER SEQUENCE #{table_name}_id_seq OWNED BY #{table_name}.id;
      SQL
    end
  end

  def _make_partitions
    0.upto(num_partitions - 1).each do |partnum|
      _make_one_partition(partnum)
    end
  end

  def _copy
    Rails.logger.info 'Setting maintenance_work_mem to 2GB'
    p(<<~SQL)
      SET maintenance_work_mem='2GB'
    SQL

    results = Benchmark.measure do
      p(<<~SQL)
        INSERT INTO "#{partitioned_table}" SELECT * FROM "#{table_name}"
      SQL
    end
    Rails.logger.info "Copy of #{table_name} to #{partitioned_table} version took #{results.real} seconds"
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

    # 0.upto(num_partitions - 1).each do |partnum|
    #   p "drop table if exists #{schema}.#{partitioned_table}_#{partnum}"
    # end

    p "DROP TABLE IF EXISTS #{partitioned_table}"

    p "ALTER TABLE IF EXISTS #{old_table} RENAME TO #{partitioned_table}"
  end

  def _compare
    [partitioned_table, old_table].each do |_schema|
      p(<<~SQL)
        EXPLAIN (ANALZYE, BUFFERS, COSTS, VERBOSE)
        select * from ...
      SQL
    end
  end

  def p(str, logit: true)
    Rails.logger.info(str.gsub(/\n/, ' ').squeeze(' ')) if logit
    base_class.connection.exec_query(str)
  end

  def table_exists?(name)
    base_class.connection.table_exists?(name)
  end

  def table_has_column?(table, column_name)
    r = p(<<~SQL, logit: false)
      SELECT count(*) AS num
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = '#{table}'
      AND column_name = '#{column_name}'
    SQL
    r.first['num'] == 1
  end

  def unique_indexes(table)
    p(<<~SQL, logit: false)
      SELECT a.indexrelid, a.relname, a.indexrelname AS "index_name", c.indexdef
      FROM
        pg_stat_user_indexes a
        JOIN pg_index b ON (b.indexrelid = a.indexrelid)
        JOIN pg_indexes c ON ( c.indexname = a.indexrelname )
      WHERE
        relname = '#{table}'
        AND b.indisunique
        AND indexrelname not like '%_pkey'
    SQL
  end

  def _default_column
    if table_has_column?(table_name, 'importer_log_id')
      'importer_log_id'
    elsif table_has_column?(table_name, 'loader_id')
      'loader_id'
    else
      raise 'could not figure out default partitioning column'
    end
  end
end
