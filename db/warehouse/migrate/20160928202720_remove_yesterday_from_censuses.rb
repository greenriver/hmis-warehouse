class RemoveYesterdayFromCensuses < ActiveRecord::Migration[4.2]
  def change
    remove_column :censuses, :yesterdays_count
    remove_column :census_by_project_types, :yesterdays_count
  end
end
