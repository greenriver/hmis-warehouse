class SetConfidentialFileNullP2 < ActiveRecord::Migration[6.1]
  def change
    # https://github.com/ankane/strong_migrations#setting-not-null-on-an-existing-column
    add_check_constraint :files, 'confidential IS NOT NULL', name: 'files_confidential_null', validate: false
  end
end
