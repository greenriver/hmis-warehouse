module AdultOnlyHouseholdsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adult_only_households, -> do
         where(she_t[:age].gteq(18).and(she_t[:other_clients_under_18].eq(0)))
      end
    end
  end
end