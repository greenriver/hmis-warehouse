class AddTurnedAwayToYouthIntake < ActiveRecord::Migration[4.2]
  def change
    add_column :youth_intakes, :turned_away, :boolean, default: false, null: false
  end
end
