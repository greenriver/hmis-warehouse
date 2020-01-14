class AddTimestampsToQualifyingActivities < ActiveRecord::Migration[4.2]
  def change
    add_timestamps :qualifying_activities
  end
end
