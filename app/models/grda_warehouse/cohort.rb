module GrdaWarehouse
  class Cohort < GrdaWarehouseBase

    scope :visible_by, -> (user) do
      all
    end
  end
end