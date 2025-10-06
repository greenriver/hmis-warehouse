###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHudLists < ActiveRecord::Migration[7.1]
  def change
    create_table :hud_list_items do |t|
      t.string :list_name, null: false
      t.string :method_name, null: false
      t.string :list_number, null: false
      t.string :label, null: false
      t.string :code, null: false
      t.integer :fiscal_year, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :hud_list_items, [:fiscal_year, :list_number, :code], unique: true, name: 'index_hud_list_items_on_year_list_and_code'
  end
end
