class MoveFileConfigsToAvailableFiles < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :available_file_tags, :document_ready, :boolean, default: false
    add_column :available_file_tags, :notification_trigger, :boolean, default: false
    add_column :available_file_tags, :consent_form, :boolean, default: false
  end
end
