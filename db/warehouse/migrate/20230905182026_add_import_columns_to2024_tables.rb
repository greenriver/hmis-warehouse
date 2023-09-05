class AddImportColumnsTo2024Tables < ActiveRecord::Migration[6.1]
  def change
    add_column :HMISParticipation, :pending_date_deleted, :date
    add_column :HMISParticipation, :source_hash, :string
    add_column :CEParticipation, :pending_date_deleted, :date
    add_column :CEParticipation, :source_hash, :string
  end
end
