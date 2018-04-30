class MadeDefaultScheduleImmediate < ActiveRecord::Migration
  def up
    remove_column :users, :email_schedule, :string
    add_column :users, :email_schedule, :string, default: 'immediate', null: false
  end
end
