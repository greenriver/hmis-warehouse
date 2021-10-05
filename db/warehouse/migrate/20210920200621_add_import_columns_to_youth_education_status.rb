class AddImportColumnsToYouthEducationStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :YouthEducationStatus, :pending_date_deleted, :date
    add_column :YouthEducationStatus, :source_hash, :string
  end
end
