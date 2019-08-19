class HomelessDefaultNull < ActiveRecord::Migration
  def change
    change_column_default :service_history_services, :homeless, nil
  end
end
