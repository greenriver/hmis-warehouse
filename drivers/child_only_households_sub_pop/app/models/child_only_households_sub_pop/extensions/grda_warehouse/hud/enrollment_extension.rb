###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ChildOnlyHouseholdsSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :child_only_households, -> do
        joins(:service_history_enrollment).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.child_only_households)
      end
    end
  end
end
