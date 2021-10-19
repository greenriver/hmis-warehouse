class AddConfidentialToExports < ActiveRecord::Migration[5.2]
  def change
    add_column :exports, :confidential, :boolean, default: false, null: false
    add_column :Organization, :confidential, :boolean, default: false, null: false
  end
end
