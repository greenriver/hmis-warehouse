module GrdaWarehouse::Confidence
  class Base < GrdaWarehouseBase
    self.table_name = :data_monitoring
    self.abstract_class = true

    scope :unprocessed, do 
      where(value: nil)
    end

    scope :queued, do
      unprocessed.
      where(arel_table[:calculate_after].lteq(Date.today))
    end

  end
end