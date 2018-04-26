class MadeDefaultScheduleImmediate < ActiveRecord::Migration
  def up
    change_column_default :users, :email_schedule, "immediate"
    User.where( email_schedule: nil ).update_all email_schedule: "immediate"
    change_column_null :users, :email_schedule, false
  end
end
