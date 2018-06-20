class AddTimestampsToQualifyingActivities < ActiveRecord::Migration
  def change
    add_timestamps :qualifying_activities
  end
end
