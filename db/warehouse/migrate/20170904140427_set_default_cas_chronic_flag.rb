class SetDefaultCasChronicFlag < ActiveRecord::Migration
  def up
    # We're splitting these into two columns, set the default for those who were 
    # previously marked
    GrdaWarehouse::Hud::Client.destination.where(sync_with_cas: true).update_all(chronically_homeless_for_cas: true)
  end
end
