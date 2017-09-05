class UpdateHmisFormsWithDsid < ActiveRecord::Migration
  def up
    c_t = GrdaWarehouse::Hud::Client.arel_table
    [1,3].each do |ds_id|
      GrdaWarehouse::HmisForm.joins(:client).
      where(c_t[:data_source_id].eq(ds_id)).
      update_all(data_source_id: ds_id)
    end
    change_column :hmis_forms, :data_source_id, :integer, null: false
  end
end
