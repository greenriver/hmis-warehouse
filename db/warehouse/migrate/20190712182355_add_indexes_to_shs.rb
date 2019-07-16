class AddIndexesToShs < ActiveRecord::Migration
  def change
    add_index :service_history_services, :date
    add_index :service_history_services, :project_type
  end
end
