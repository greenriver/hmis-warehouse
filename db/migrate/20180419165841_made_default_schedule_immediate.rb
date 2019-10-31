class MadeDefaultScheduleImmediate < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :email_schedule, :string
    add_column :users, :email_schedule, :string, default: 'immediate', null: false
  end
end
