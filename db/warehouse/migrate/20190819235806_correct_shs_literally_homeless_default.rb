class CorrectShsLiterallyHomelessDefault < ActiveRecord::Migration
  def change
    change_column_default :service_history_services, :literally_homeless, nil
  end
end
