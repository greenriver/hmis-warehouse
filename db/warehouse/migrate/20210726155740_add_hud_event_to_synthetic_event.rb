class AddHudEventToSyntheticEvent < ActiveRecord::Migration[5.2]
  def change
    add_reference :synthetic_events, :hud_event
  end
end
