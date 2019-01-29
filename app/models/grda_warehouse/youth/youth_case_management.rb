module GrdaWarehouse::Youth
  class YouthCaseManagement < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid

    def self.available_activities
      [
        'Prevention ',
        'Re-Housing',
      ]
    end
  end
end