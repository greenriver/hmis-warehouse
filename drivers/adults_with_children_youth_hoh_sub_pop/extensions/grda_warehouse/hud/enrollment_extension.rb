###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenYouthHohSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adults_with_children_youth_hoh, -> do
        joins(:service_history_enrollment).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.adults_with_children_youth_hoh)
      end
    end
  end
end
