class RenameEdIpVisitToLoadedEdIpVisit < ActiveRecord::Migration[5.2]
  def change
    rename_table :ed_ip_visits, :loaded_ed_ip_visits
  end
end
