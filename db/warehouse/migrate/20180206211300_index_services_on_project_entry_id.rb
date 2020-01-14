class IndexServicesOnProjectEntryId < ActiveRecord::Migration[4.2]
  def change
    add_index :Services, [:ProjectEntryID, :PersonalID, :data_source_id], name: :index_serv_on_proj_entry_per_id_ds_id
  end
end
