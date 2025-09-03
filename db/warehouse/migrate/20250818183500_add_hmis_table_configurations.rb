###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddHmisTableConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :hmis_table_configurations do |t|
      t.references :data_source, null: false # HMIS Data Source that configuration belongs to
      t.string :table_key, null: false # Key identifying which table is being configured
      t.references :owner, polymorphic: true, index: true # Optional owner of the config. Empty for globally configured tables.
      t.jsonb :columns, null: false, default: [] # JSONB for column configurations
      t.jsonb :filters, null: false, default: [] # JSONB for filter configurations

      t.timestamps
    end

    add_index :hmis_table_configurations, [:table_key, :owner_type, :owner_id, :data_source_id], unique: true, where: 'owner_type IS NOT NULL AND owner_id IS NOT NULL', name: 'uniq_hmis_table_configs_owner'
    add_index :hmis_table_configurations, [:table_key, :data_source_id], unique: true, where: 'owner_type IS NULL AND owner_id IS NULL', name: 'uniq_hmis_table_configs_global'
  end
end
