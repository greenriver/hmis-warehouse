module GrdaWarehouse
  class CohortClient < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :cohort
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :cohort_client_notes

    validates_presence_of :cohort, :client
    
  end
end