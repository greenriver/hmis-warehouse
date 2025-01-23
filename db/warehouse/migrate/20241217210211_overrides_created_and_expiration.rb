class OverridesCreatedAndExpiration < ActiveRecord::Migration[7.0]
  def change
    add_column :import_overrides, :created_by, :bigint
    add_column :import_overrides, :expires_on, :date
  end
end
