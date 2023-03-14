class AddServiceTypeToInstances < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_instances, :custom_service_type_id, :integer
    add_column :hmis_form_instances, :custom_service_category_id, :integer
  end
end
