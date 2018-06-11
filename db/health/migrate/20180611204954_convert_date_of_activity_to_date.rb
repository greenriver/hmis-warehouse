class ConvertDateOfActivityToDate < ActiveRecord::Migration
  def change
    change_column :qualifying_activities, :date_of_activity, :date
  end
end
