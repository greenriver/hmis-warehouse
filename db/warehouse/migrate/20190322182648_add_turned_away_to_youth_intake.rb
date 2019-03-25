class AddTurnedAwayToYouthIntake < ActiveRecord::Migration
  def change
    add_column :youth_intakes, :turned_away, :boolean, default: false, null: false
  end
end
