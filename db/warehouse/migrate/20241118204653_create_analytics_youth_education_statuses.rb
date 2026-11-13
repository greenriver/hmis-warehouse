###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsYouthEducationStatuses < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.youth_education_statuses'
  end
end
