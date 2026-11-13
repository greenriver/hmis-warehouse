###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAggregatedEnrollmentForFy2026 < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_aggregated_enrollments, :MentalHealthConsultation, :integer
  end
end
