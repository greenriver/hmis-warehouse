class AddVispdatPriorityDaysHomeless < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :vispdat_prioritization_days_homeless, :integer
  end
end
