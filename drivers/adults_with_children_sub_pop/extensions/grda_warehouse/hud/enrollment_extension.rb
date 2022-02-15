###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adults_with_children, -> do
        joins(:service_history_enrollment).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.adults_with_children)
      end
    end
  end
end
