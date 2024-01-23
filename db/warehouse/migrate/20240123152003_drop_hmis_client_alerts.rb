class DropHmisClientAlerts < ActiveRecord::Migration[6.1]
  def change
    safety_assured { drop_table( 'hmis_client_alerts') }
  end
end
