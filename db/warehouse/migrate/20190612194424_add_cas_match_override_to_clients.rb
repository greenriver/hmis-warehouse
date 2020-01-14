class AddCasMatchOverrideToClients < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :cas_match_override, :date
  end
end
