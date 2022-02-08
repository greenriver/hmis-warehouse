###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::GenerateServiceHistoryLog < GrdaWarehouseBase
  self.table_name = 'generate_service_history_log'
  include ActionView::Helpers::DateHelper

  has_many :generate_service_history_batch_logs

  def import_time
    completed_at = generate_service_history_batch_logs.maximum(:updated_at)
    return nil unless completed_at && started_at

    seconds = ((completed_at - started_at)/1.minute).round * 60
    distance_of_time_in_words(seconds)
  end

  def clients_processed
    generate_service_history_batch_logs.sum(:updated) + generate_service_history_batch_logs.sum(:patched)
  end

  def total_clients
    generate_service_history_batch_logs.sum(:to_process)
  end

  def clients_updated
    generate_service_history_batch_logs.sum(:updated)
  end

  def clients_patched
    generate_service_history_batch_logs.sum(:patched)
  end
end
