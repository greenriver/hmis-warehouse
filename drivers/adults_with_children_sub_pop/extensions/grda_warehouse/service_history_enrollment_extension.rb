module AdultsWithChildrenSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :adults_with_children, -> do
         where(
           she_t[:age].gteq(18).and(she_t[:other_clients_under_18].gt(0)).
           or(she_t[:age].lt(18).
            and(
              she_t[:other_clients_between_18_and_25].gt(0).
              or(she_t[:other_clients_over_25].gt(0))
            )
          )
        )
      end
    end
  end
end