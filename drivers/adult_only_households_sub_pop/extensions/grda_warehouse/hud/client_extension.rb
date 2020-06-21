module AdultOnlyHouseholdsSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :adult_only_households, -> do
        where(
         GrdaWarehouse::ServiceHistoryEnrollment.entry.adult_only_households.
          where(she_t[:client_id].eq(c_t[:id])).arel.exists
        )
      end
    end
  end
end
