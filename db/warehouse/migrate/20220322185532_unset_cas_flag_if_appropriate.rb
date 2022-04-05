class UnsetCasFlagIfAppropriate < ActiveRecord::Migration[6.1]
  def up
    # Don't do anything if our current method of sync'ing with CAS is based on individual flagging
    return if GrdaWarehouse::Config.get(:cas_available_method)&.to_sym == :cas_flag

    GrdaWarehouse::Hud::Client.where(sync_with_cas: true).update_all(sync_with_cas: false)
  end
end
