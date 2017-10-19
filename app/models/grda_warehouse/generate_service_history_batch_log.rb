class GrdaWarehouse::GenerateServiceHistoryBatchLog < GrdaWarehouseBase
  include ActionView::Helpers::DateHelper
    belongs_to :generate_service_history_log
  
end