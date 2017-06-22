class AddUniquenessConstraintToServicesTable < ActiveRecord::Migration
  def change
    cz = GrdaWarehouse::Hud::Service
    add_index cz.table_name, [ :data_source_id, :PersonalID, :RecordType, :ProjectEntryID, :DateProvided ], name: :index_services_ds_id_p_id_type_entry_id_date
  end
end
