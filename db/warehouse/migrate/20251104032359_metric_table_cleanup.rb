###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class MetricTableCleanup < ActiveRecord::Migration[7.1]
  def up
    remove_index :metric_definitions, name: 'index_metric_definitions_on_category'
    remove_index :metric_definitions, name: 'index_metric_definitions_on_active'
    remove_index :metric_calculation_runs, name: 'index_metric_calculation_runs_on_status'
  end
end
