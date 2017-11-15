class AddDaysInLastThreeYearsToHudChronics < ActiveRecord::Migration
  def change
    add_column :hud_chronics, :days_in_last_three_years, :integer
  end
end
