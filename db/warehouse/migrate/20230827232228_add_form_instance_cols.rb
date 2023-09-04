class AddFormInstanceCols < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_instances, :other_funder, :string, null: true
    add_column :hmis_form_instances, :data_collected_about, :string, null: true
    add_column :hmis_form_instances, :system, :boolean, null: false, default: false
    add_column :hmis_form_instances, :active, :boolean, null: false, default: true
  end
end
