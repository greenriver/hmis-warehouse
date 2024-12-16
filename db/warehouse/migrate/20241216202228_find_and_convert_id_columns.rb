class FindAndConvertIdColumns < ActiveRecord::Migration[7.0]
  def up
    return unless runnable?

    safety_assured {_up}
  end

  def down
    return unless runnable?

    raise ActiveRecord::IrreversibleMigration,
      "Converting bigint primary keys back to integer is unsafe as it may cause data loss"
  end

  protected

  def runnable?
    # we handle this manually in production and staging
    Rails.env.development? || Rails.env.test?
  end

  def _up
    # Find all integer columns ending in _id
    columns_to_convert = execute(<<-SQL).to_a
      SELECT DISTINCT
        t.table_name,
        c.column_name
      FROM information_schema.tables t
      JOIN information_schema.columns c
        ON t.table_schema = c.table_schema
        AND t.table_name = c.table_name
      WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
      AND c.data_type = 'integer'
      AND c.column_name LIKE '%_id'
    SQL

    # Print out what we're going to change
    messages = columns_to_convert.map do |row|
      "#{row['table_name']}.#{row['column_name']}"
    end
    Rails.logger.info("Columns to convert to bigint, #{messages.join(', ')}")

    # Do the conversion
    columns_to_convert.each do |row|
      execute <<-SQL
        ALTER TABLE "#{row['table_name']}" ALTER COLUMN "#{row['column_name']}" TYPE bigint
      SQL
    end
  end
end
