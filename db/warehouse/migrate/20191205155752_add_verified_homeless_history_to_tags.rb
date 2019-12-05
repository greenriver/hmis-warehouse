class AddVerifiedHomelessHistoryToTags < ActiveRecord::Migration
  def change
    add_column :configs, :verified_homeless_history, :boolean, default: false, null: false
  end
end
