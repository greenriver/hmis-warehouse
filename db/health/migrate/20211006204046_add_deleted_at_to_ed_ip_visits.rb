class AddDeletedAtToEdIpVisits < ActiveRecord::Migration[5.2]
  def change
    add_column :ed_ip_visits, :deleted_at, :timestamp
  end
end
