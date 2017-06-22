class RemoveContactIdFromProjectDataQuality < ActiveRecord::Migration
  def change
    remove_column :project_data_quality, :project_contact_id, :integer
  end
end
