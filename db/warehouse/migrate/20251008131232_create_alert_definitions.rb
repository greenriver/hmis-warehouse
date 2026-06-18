###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAlertDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :alert_definitions do |t|
      t.string :code, null: false, comment: "Unique identifier (e.g., 'new_account')"
      t.string :name, null: false, comment: "Display name (e.g., 'New Account Creation')"
      t.string :category, null: false, comment: "Grouping category (e.g., 'system', 'data_quality')"
      t.text :description, comment: 'Human-readable description'
      t.boolean :active, default: true, null: false, comment: 'Enable/disable without deletion'
      t.timestamps
    end

    add_index :alert_definitions, :code, unique: true
    add_index :alert_definitions, :category
  end
end
