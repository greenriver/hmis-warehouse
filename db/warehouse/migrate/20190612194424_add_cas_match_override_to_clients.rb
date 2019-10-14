class AddCasMatchOverrideToClients < ActiveRecord::Migration
  def change
    add_column :Client, :cas_match_override, :date
  end
end
