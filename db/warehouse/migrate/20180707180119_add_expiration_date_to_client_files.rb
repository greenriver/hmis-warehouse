class AddExpirationDateToClientFiles < ActiveRecord::Migration
  def change
    add_column :files, :expiration_date, :date
    add_column :available_file_tags, :requires_effective_date, :boolean, default: false, null: false
    add_column :available_file_tags, :requires_expiration_date, :boolean, default: false, null: false
  end
end
