class SetConfidentialFileNullP3 < ActiveRecord::Migration[6.1]
  def up
    # https://github.com/ankane/strong_migrations#setting-not-null-on-an-existing-column
    validate_check_constraint :files, name: 'files_confidential_null'

    # in Postgres 12+, you can then safely set NOT NULL on the column
    change_column_null :files, :confidential, false
    remove_check_constraint :files, name: 'files_confidential_null'
  end

  def down
    add_check_constraint :files, 'confidential IS NOT NULL', name: 'files_confidential_null', validate: false
    change_column_null :files, :confidential, true
  end
end
