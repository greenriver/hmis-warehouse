class AddNotificationScheduleToUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.string :email_schedule
    end
  end
end
