###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveDuplicativeIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :metric_snapshots,
                 [:entity_type, :entity_id, :metric_definition_id, :initial_observation_date],
                 name: 'index_metric_snapshots_for_time_series'
  end
end
