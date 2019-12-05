class AddVerifiedHomelessHistoryToTags < ActiveRecord::Migration
  def change
    add_column :configs, :verified_homeless_history_visible_to_all, :boolean, default: false, null: false
    add_column :available_file_tags, :verified_homeless_history, :boolean, default: false, null: false
  end
end
