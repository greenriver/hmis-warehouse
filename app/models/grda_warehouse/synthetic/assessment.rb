module GrdaWarehouse::Synthetic
  class Assessment < GrdaWarehouseBase
    self.table_name = 'synthetic_assessments'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true

    validates_presence_of :enrollment
    validates_presence_of :client
  end
end
