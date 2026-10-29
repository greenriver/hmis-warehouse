###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AllowNullAssessmentFields < ActiveRecord::Migration[8.1]
  def change
    [:AssessmentLocation, :AssessmentType, :AssessmentLevel, :PrioritizationStatus].each do |column|
      change_column_null :Assessment, column, true
    end
  end
end
