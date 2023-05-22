class PrimaryDbLoad < ActiveRecord::Migration[6.1]
  # This migration replaces everything that comes before
  # The process for making this is to grab a copy of the appropriate structure.sql file
  # from a commit where the CI is passing (preferably from the stable branch.)
  # Place it in `db/structures/appropriate.sql`
  # Comment out any lines with `ar_internal_metadata`
  # Comment out any lines with `schema_migrations`
  # Delete the schema_migrations insert from the bottom of the file
  def up
    ApplicationRecord.connection.execute(IO.read(Rails.root.join('db', 'structures', 'primary.sql')))
  end
end
