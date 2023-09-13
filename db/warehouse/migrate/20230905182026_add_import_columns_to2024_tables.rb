class AddImportColumnsTo2024Tables < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)

    add_column :HMISParticipation, :pending_date_deleted, :date
    add_column :HMISParticipation, :source_hash, :string
    add_column :CEParticipation, :pending_date_deleted, :date
    add_column :CEParticipation, :source_hash, :string

    add_index :HMISParticipation, [:data_source_id, :HMISParticipationID], unique: true, name: :ds_hmisparticipation_idx
    add_index :CEParticipation, [:data_source_id, :CEParticipationID], unique: true, name: :ds_ceparticipation_idx
  end
end
