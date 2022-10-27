# https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE

class DBA::PartitionMaker
  attr_accessor :base_class
  attr_accessor :klass
  attr_accessor :num_partitions
  attr_accessor :old_table
  attr_accessor :partition_column
  attr_accessor :partitioned_table
  attr_accessor :schema

  # Create a normal, non-partitioned table/model first, and pass in the class
  def initialize(num_partitions: 71, partition_column: nil, schema: 'hmis', table_name:)
    self.klass = klass
    self.num_partitions = num_partitions
    self.old_table = "#{table_name}_saved"
    self.partitioned_table = table_name
    self.base_class = GrdaWarehouseBase
    self.partition_column = partition_column || _default_column
    self.schema = schema
  end

  def start_over!
    _trash_it_all
  end

  def run!
    _schema
    _main_table
    _sub_tables
    _copy
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
      p(<<~SQL)
        ALTER TABLE "#{partitioned_table}" RENAME TO "#{old_table}";
      SQL

      temp = "#{partitioned_table}_temp"

      p(<<~SQL)
        CREATE TABLE "#{temp}" (LIKE "#{old_table}" INCLUDING ALL)
      SQL

      p(<<~SQL)
        ALTER TABLE "#{temp}" DROP CONSTRAINT #{temp}_pkey
      SQL

      p(<<~SQL)
        ALTER TABLE "#{temp}" ADD PRIMARY KEY (id, #{partition_column})
      SQL

      # FIXME: TODO: handle unique indexes as well
      Rails.logger.warn "Not checking for other unique indexes. They all need to include #{partition_column}."

      p(<<~SQL)
        CREATE TABLE "#{partitioned_table}" (LIKE "#{temp}" INCLUDING ALL)
          PARTITION BY HASH ("#{partition_column}")
      SQL

      p(<<~SQL)
        DROP TABLE "#{temp}"
      SQL
    end
  end

  def _sub_tables
    0.upto(num_partitions - 1).each do |partnum|
      _one_sub_table(partnum)
    end
  end

  def _copy
    results = Benchmark.measure do
      p(<<~SQL)
        INSERT INTO "#{partitioned_table}" select * from "#{old_table}"
      SQL
    end
    Rails.logger.info "Copy of #{partitioned_table} to partitioned version took #{results.real} seconds"
  end

  def _one_sub_table(partnum)
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

  def p(str)
    Rails.logger.info str
    base_class.connection.exec_query(str)
  end

  def table_exists?(name)
    base_class.connection.table_exists?(name)
  end

  def table_has_column?(table_name, column_name)
    r = p(<<~SQL)
      SELECT count(*) AS num
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = '#{table_name}'
      AND column_name = '#{column_name}'
    SQL
    r.first['num'] == 1
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
