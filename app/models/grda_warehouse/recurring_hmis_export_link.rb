module GrdaWarehouse
  class RecurringHmisExportLink  < GrdaWarehouseBase
    belongs_to :hmis_export
    belongs_to :recurring_hmis_export
  end
end