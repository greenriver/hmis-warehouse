class AddNotificationScheduleToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :email_schedule
    end
  end
end
