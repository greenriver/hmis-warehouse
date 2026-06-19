###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddProviderComparisonConfig < ActiveRecord::Migration[7.1]
  def change
    add_column :performance_measurement_goals, :provider_comparisons_visible, :boolean, null: false, default: false
  end
end
