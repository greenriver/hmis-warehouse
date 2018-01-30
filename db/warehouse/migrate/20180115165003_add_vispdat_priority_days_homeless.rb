class AddVispdatPriorityDaysHomeless < ActiveRecord::Migration
  def change
    add_column :Client, :vispdat_prioritization_days_homeless, :integer
  end
end
