###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsAssessmentQuestionsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view 'analytics.assessment_questions', version: 2, revert_to_version: 1
  end
end
