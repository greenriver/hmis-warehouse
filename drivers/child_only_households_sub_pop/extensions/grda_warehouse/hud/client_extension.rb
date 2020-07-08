module ChildOnlyHouseholdsSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :child_only_households, -> do
        where(
         GrdaWarehouse::ServiceHistoryEnrollment.entry.child_only_households.
          where(she_t[:client_id].eq(c_t[:id])).arel.exists
        )
      end

      scope :child, -> (on: Date.current) do
        where(c_t[:DOB].gt(on - 18.years))
      end
    end
  end
end
