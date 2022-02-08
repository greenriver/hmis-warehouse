###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class Base < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid
    self.table_name = :warehouse_reports
    belongs_to :user, optional: true
    scope :ordered, -> { order(created_at: :desc) }

    scope :for_list, -> do
      select(column_names - ['data', 'support'])
    end

    scope :for_user, -> (user) do
      where(user_id: user.id)
    end

    def completed_in
      if completed?
        seconds = ((finished_at - started_at)/1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'incomplete'
      end
    end

    def status
      if started_at
        completed_in
      else
        'queued'
      end
    end

    def completed?
      finished_at && started_at
    end

  end
end
