module GrdaWarehouse
  class CohortClientNote < GrdaWarehouseBase
    belongs_to :cohort_client

    validates_presence_of :cohort_client, :note
    
  end
end