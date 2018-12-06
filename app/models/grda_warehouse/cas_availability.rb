module GrdaWarehouse
  class CasAvailability < GrdaWarehouseBase
    
    scope :available_between, -> (start_date:, end_date:) do
      where(
        arel_table[:available_at].lt(end_date).
        and(
          arel_table[:unavailable_at].gt(start_date).
          or(arel_table[:unavailable_at].eq(nil))
        )
      )
    end

    scope :already_available, -> do
      where(unavailable_at: nil)
    end

  end
end