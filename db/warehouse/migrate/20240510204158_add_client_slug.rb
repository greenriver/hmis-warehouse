class AddClientSlug < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    [
      'Client',
      'Enrollment',
    ].each do |table_name|
      col_name = :client_slug
      # Postgres doesn't currently support virtual columns yet, so storing them.
      next if column_exists?(table_name.to_sym, col_name)

      column_def = <<~SQL
        ("PersonalID" || ':' || "data_source_id"::text)
      SQL
      add_column(
        table_name.to_sym,
        col_name,
        :string,
        as: column_def,
        stored: true,
      )
      add_index table_name.to_sym, col_name, algorithm: :concurrently
    end
  end
end
