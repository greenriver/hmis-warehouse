class GrdaWarehouse::GenerateServiceHistoryLog < GrdaWarehouseBase
  self.table_name = 'generate_service_history_log'
  include ActionView::Helpers::DateHelper

  def import_time
    if completed_at.present?
      seconds = ((completed_at - started_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    else
      'incomplete'
    end
  end
end