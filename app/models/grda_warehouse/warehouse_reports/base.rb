###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports
  class Base < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    acts_as_paranoid
    self.table_name = :warehouse_reports
    belongs_to :user, optional: true
    scope :ordered, -> { order(updated_at: :desc) }

    scope :for_list, -> do
      select(column_names - ['data', 'support'])
    end

    scope :for_user, ->(user) do
      where(user_id: user.id)
    end

    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    def completed_in
      if completed?
        seconds = ((finished_at - started_at) / 1.minute).round * 60
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
