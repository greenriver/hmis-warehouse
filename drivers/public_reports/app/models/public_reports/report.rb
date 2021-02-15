###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class Report < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    belongs_to :user
    scope :viewable_by, ->(user) do
      return current_scope if user.can_view_all_reports?

      where(user_id: user.id)
    end

    def status
      if started_at.blank?
        "Queued at #{created_at}"
      elsif started_at.present? && completed_at.blank?
        if started_at < 24.hours.ago
          'Failed'
        else
          "Running since #{started_at}"
        end
      elsif completed?
        'Complete'
      end
    end

    def completed?
      completed_at.present?
    end

    def filter_object
      @filter_object ||= ::Filters::FilterBase.new.set_from_params(filter['filters'].merge(enforce_one_year_range: false).with_indifferent_access)
    end

    def published?
      published_url.present?
    end
  end
end
