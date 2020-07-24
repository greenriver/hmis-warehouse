class SetSoundex < ActiveRecord::Migration[5.2]
  def up
    PIIAttributeSupport.allow_all_pii!

    puts "Processing: #{GrdaWarehouse::Hud::Client.with_deleted.count}"
    GrdaWarehouse::Hud::Client.update_all_soundex!
  end
end
