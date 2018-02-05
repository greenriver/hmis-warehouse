module GrdaWarehouse
  class CohortClientChange < GrdaWarehouseBase
    belongs_to :cohort
    belongs_to :cohort_client
    has_one :client, through: :cohort_client
    belongs_to :user

    validates_presence_of :cohort_client, :cohort, :user, :change
  end
end