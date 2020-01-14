class RemoveContactIdFromProjectDataQuality < ActiveRecord::Migration[4.2]
  def change
    remove_column :project_data_quality, :project_contact_id, :integer
  end
end
