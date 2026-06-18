###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTotalCostToHopwaCaperEnrollments < ActiveRecord::Migration[7.1]
  def change
    add_column :hopwa_caper_enrollments, :total_project_cost, :decimal, precision: 10, scale: 2
  end
end
