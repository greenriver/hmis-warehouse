module GrdaWarehouse
  class CohortClientNote < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :cohort_client
    has_one :client, through: :cohort_client
    belongs_to :user

    validates_presence_of :cohort_client, :note

    scope :ordered, -> do
      order(updated_at: :desc)
    end
    
  end
end