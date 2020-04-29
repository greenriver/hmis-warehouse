###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Export # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern
  include ArelHelper
  included do
    def filter
      @filter ||= ::Filters::DateRangeAndSources.new(options)
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

    private def clients_within_age_range
      @clients_within_age_range ||= GrdaWarehouse::Hud::Client.destination.
        age_group_within_range(start_age: filter.start_age, end_age: filter.end_age, start_date: filter.start, end_date: filter.end)
    end

    private def clients_within_projects
      @clients_within_projects ||= begin
        GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :project).
          merge(GrdaWarehouse::Hud::Project.viewable_by(filter.user).where(id: filter.effective_project_ids))
      end
    end

    private def clients_with_ongoing_enrollments(clients)
      clients.joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: filter.start, end_date: filter.end))
    end

    private def heads_of_household(clients)
      clients.joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households)
    end

    def yes_no(bool)
      bool ? 'Yes' : 'No'
    end
  end
end
