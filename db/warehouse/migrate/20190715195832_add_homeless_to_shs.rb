class AddHomelessToShs < ActiveRecord::Migration
  def change
    add_column :service_history_services, :homeless, :boolean, default: false
  end
end

