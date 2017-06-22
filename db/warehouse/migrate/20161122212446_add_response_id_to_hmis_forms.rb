class AddResponseIdToHmisForms < ActiveRecord::Migration
  def change
    add_column :hmis_forms, :response_id, :integer
    add_column :hmis_forms, :subject_id, :integer
  end
end
