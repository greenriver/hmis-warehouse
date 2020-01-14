class AddLiterallyHomelessToShs < ActiveRecord::Migration[4.2]
  def change
    add_column :service_history_services, :homeless, :boolean, default: nil
    add_column :service_history_services, :literally_homeless, :boolean, default: nil
  end
end
