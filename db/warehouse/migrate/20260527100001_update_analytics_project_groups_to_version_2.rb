###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateAnalyticsProjectGroupsToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view 'analytics.project_groups', version: 2, revert_to_version: 1
  end
end
