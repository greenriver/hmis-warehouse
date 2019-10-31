class AddDataSourceToHmisForms < ActiveRecord::Migration[4.2]
  def change
    add_column :hmis_forms, :data_source_id, :integer
    add_column :hmis_forms, :site_id, :integer
  end
end
