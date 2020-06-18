module YouthParentsSubPop::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      scope :youth_parents, -> (start_date: Date.current, end_date: Date.current) do
        youth(on: start_date).
          where(
            id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
              open_between(start_date: start_date, end_date: end_date).
              distinct.
              youth_parents.
              select(:client_id)
          )
      end
    end
  end
end