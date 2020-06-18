module YouthParentsSubPop::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :youth_parents, -> do
        where(parenting_youth: true).
          where(she_t[:head_of_household].eq(true))
      end
    end
  end
end