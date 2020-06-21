module ChildOnlyHouseholdsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :child_only_households, -> do
         where(children_only: true)
      end
    end
  end
end