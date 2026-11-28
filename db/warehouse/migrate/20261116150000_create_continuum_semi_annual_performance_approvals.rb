###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateContinuumSemiAnnualPerformanceApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :continuum_semi_annual_performance_approvals do |t|
      t.references :report_instance, null: false, foreign_key: { to_table: :simple_report_instances }
      t.references :user, null: false
      t.boolean :approved, null: false
      t.datetime :created_at, null: false
    end
  end
end
