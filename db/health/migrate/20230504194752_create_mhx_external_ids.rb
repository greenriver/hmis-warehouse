###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMhxExternalIds < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_external_ids do |t|
      t.references :client, null: false, unique: true
      t.string :identifier, null: false, index: true, unique: true
      t.datetime :invalidated_at

      t.timestamps
    end
  end
end
