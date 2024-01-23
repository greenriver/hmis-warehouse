class DropHmisClientAlerts < ActiveRecord::Migration[6.1]
  def change
    # No need for this migration to be reversible; this table was never used
    safety_assured { drop_table( 'hmis_client_alerts') }
  end
end
