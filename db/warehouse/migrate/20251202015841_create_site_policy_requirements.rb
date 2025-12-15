###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateSitePolicyRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :compliance_requirements do |t|
      t.string :name, null: false
      t.references :content_page, null: false, foreign_key: true
      t.integer :revision, null: false, default: 1
      t.integer :expires_after_days
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
