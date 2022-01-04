class AddEmailToDataQuality < ActiveRecord::Migration[5.2]
  def change
    add_column :project_data_quality, :notify_contacts, :boolean, default: false
  end
end
