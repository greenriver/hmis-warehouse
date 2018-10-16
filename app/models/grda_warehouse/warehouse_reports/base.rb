module GrdaWarehouse::WarehouseReports
  class Base < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = :warehouse_reports
    belongs_to :user, required: false
    scope :ordered, -> { order(created_at: :desc) }

    scope :for_list, -> do
      select(column_names - ['data', 'support'])
    end


    def completed_in
      if finished_at && started_at
        seconds = ((finished_at - started_at)/1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'incomplete'
      end
    end
  end
end