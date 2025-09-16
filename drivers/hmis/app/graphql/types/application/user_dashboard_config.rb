###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::UserDashboardConfig < Types::BaseObject
    skip_activity_log

    field :id, ID, null: false
    field :show_staff_assignment, Boolean, null: false
    field :show_referrals, Boolean, null: false
  end
end
