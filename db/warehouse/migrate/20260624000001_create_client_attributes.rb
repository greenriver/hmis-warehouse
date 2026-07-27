###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateClientAttributes < ActiveRecord::Migration[7.2]
  def change
    create_table :client_attributes do |t|
      t.bigint  :client_id, null: false
      t.boolean :external_data_sharing_exclusion_flag
      t.bigint  :external_data_sharing_updated_by
      t.datetime :external_data_sharing_updated_at
      t.timestamps
    end
    add_index :client_attributes, :client_id, unique: true
  end
end
