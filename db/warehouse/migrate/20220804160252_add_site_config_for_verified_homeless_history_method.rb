class AddSiteConfigForVerifiedHomelessHistoryMethod < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :verified_homeless_history_method, :string, default: :visible_in_window
  end
end
