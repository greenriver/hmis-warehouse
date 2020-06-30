module ChildOnlyHouseholdsSubPop::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :child_only_households, ->  do
        joins(:service_history_enrollment).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.child_only_households)
      end
    end
  end
end