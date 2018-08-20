module GrdaWarehouse
  class CohortColumnOption < GrdaWarehouseBase
    validates_presence_of :cohort_column, :weight
    
    def cohort_columns 
      [
        'Housing Track Suggested', 
        'Housing Track Enrolled',
      ]
    end
  end
end
