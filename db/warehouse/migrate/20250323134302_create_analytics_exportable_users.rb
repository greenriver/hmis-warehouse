# frozen_string_literal: true

# note, there is no active record model for this table
class CreateAnalyticsExportableUsers < ActiveRecord::Migration[7.0]
  def change
    create_table 'analytics.app_users', id: false do |t|
      t.bigint :id, null: false
      t.string :first_name
      t.string :last_name
      t.string :email
    end
    add_index 'analytics.app_users', :id, unique: true
  end
end
