class AddLiterallyHomelessToShs < ActiveRecord::Migration
  def change
    add_column :service_history_services, :literally_homeless, :boolean, default: false
  end
end
