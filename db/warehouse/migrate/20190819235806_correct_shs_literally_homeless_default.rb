class CorrectShsLiterallyHomelessDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :service_history_services, :literally_homeless, nil
  end
end
