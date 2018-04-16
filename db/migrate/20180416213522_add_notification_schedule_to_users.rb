class AddNotificationScheduleToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.boolean :notify_daily, null: false, default: true
    end
  end
end
