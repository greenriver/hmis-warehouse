class AddDaysInLastThreeYearsToHudChronics < ActiveRecord::Migration[4.2]
  def change
    add_column :hud_chronics, :days_in_last_three_years, :integer
  end
end
