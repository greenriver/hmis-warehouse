###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddProviderComparisonConfig < ActiveRecord::Migration[7.1]
  def change
    add_column :performance_measurement_goals, :provider_comparisons_visible, :boolean, null: false, default: false
  end
end
