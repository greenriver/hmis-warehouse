###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDataSourceIdToWfdTemplate < ActiveRecord::Migration[7.0]
  def change
    safety_assured do # not yet used in prod, so safety_assured is ok
      add_column :wfd_templates, :data_source_id, :integer, null: true

      add_index :wfd_templates, :data_source_id

      # We want the column to be required, but need to fill in a default value on all the existing records.
      # Since they are non-prod records that were populated by the starter pack,
      # we can just rerun the starter pack later to get the actual correct data source ID in each environment,
      # so for now just use 0.
      reversible do |dir|
        dir.up do
          execute <<~SQL
          UPDATE wfd_templates
          SET data_source_id = 0
        SQL
        end
      end

      change_column_null :wfd_templates, :data_source_id, false
    end
  end
end
