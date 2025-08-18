###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddHmisTableConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :hmis_table_configurations do |t|
      t.bigint :data_source_id, null: false # HMIS Data Source that configuration belongs to
      t.string :table_key, null: false # Key identifying which table is being configured
      t.references :owner, polymorphic: true, index: true # Optional owner of the config. Empty for globally configured tables.
      t.jsonb :columns, null: false, default: [] # JSONB for column configurations
      t.jsonb :filters, null: false, default: [] # JSONB for filter configurations

      t.timestamps
    end

    add_index :hmis_table_configurations, [:table_key, :owner_type, :owner_id, :data_source_id], unique: true, name: 'index_hmis_table_configurations_on_key_owner_and_source'
  end
end
