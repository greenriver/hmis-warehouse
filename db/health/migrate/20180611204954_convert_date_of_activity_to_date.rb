class ConvertDateOfActivityToDate < ActiveRecord::Migration[4.2]
  def change
    change_column :qualifying_activities, :date_of_activity, :date
  end
end
