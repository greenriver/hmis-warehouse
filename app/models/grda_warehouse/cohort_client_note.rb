module GrdaWarehouse
  class CohortClientNote < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :cohort_client

    validates_presence_of :cohort_client, :note
    
  end
end