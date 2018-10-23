class GrdaWarehouse::GenerateServiceHistoryLog < GrdaWarehouseBase
  self.table_name = 'generate_service_history_log'
  include ActionView::Helpers::DateHelper

  has_many :generate_service_history_batch_logs

  def import_time
    completed_at = generate_service_history_batch_logs.max { |left, right| left.updated_at <=> right.updated_at }.updated_at
    seconds = ((completed_at - started_at)/1.minute).round * 60
    distance_of_time_in_words(seconds)
  end

  def clients_processed
    generate_service_history_batch_logs.reduce(0) { |sum, batch| sum += batch.updated + batch.patched }
  end

  def total_clients
    generate_service_history_batch_logs.reduce(0) { |sum, batch| sum += batch.to_process }
  end

  def clients_updated
    generate_service_history_batch_logs.reduce(0) { |sum, batch| sum += batch.updated }
  end

  def clients_patched
    generate_service_history_batch_logs.reduce(0) { |sum, batch| sum += batch.patched }
  end
end