###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateContentPages < ActiveRecord::Migration[7.1]
  def change
    create_table :content_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content, null: false
      # References app db users table - no FK constraint across databases
      t.references :updated_by, null: true, index: false
      t.timestamps
      t.datetime :deleted_at

      t.index :slug, unique: true, where: 'deleted_at IS NULL'
    end
  end
end
