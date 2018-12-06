module GrdaWarehouse
  class CasNonHmisClientHistory < GrdaWarehouseBase
    
    scope :available_between, -> (start_date:, end_date:) do
      where(
        arel_table[:available_on].lt(end_date).
        and(
          arel_table[:unavailable_on].gt(start_date).
          or(arel_table[:unavailable_on].eq(nil))
        )
      )
    end
  end
end