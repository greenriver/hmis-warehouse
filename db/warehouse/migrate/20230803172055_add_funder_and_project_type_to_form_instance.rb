class AddFunderAndProjectTypeToFormInstance < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_form_instances, :funder, :integer, null: true
    add_column :hmis_form_instances, :project_type, :integer, null: true
  end
end
