###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Export
  extend ActiveSupport::Concern
  include ArelHelper
  included do
    def key_for_display(key)
      case key
      when 'data_source_ids'
        'data sources'
      when 'project_ids'
        'projects'
      when 'organization_ids'
        'organizations'
      else
        key.humanize.downcase
      end
    end

    def value_for_display(key, value)
      value = case key
      when 'user_id'
        User.find_by(id: value)&.name
      when 'sub_population'
        GrdaWarehouse::WarehouseReports::Dashboard::Base.available_sub_populations.invert[value.to_sym]
      when 'data_source_ids'
        GrdaWarehouse::DataSource.where(id: value).map(&:short_name)
      when 'project_ids'
        GrdaWarehouse::Hud::Project.where(id: value).map(&:name_and_type)
      when 'organization_ids'
        GrdaWarehouse::Hud::Organization.where(id: value).map(&:OrganizationName)
      else
        value
      end
      return value unless value.is_a?(Array)

      text = value[0...5].to_sentence(last_word_connector: ', ').to_s
      text += ', ...' if value.count > 5
      text
    end

    def filter
      @filter ||= ::Filters::DateRangeAndSourcesResidentialOnly.new(options)
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
      @clients_within_age_range ||= GrdaWarehouse::Hud::Client.
        destination.
        age_group_within_range(
          start_age: filter.start_age,
          end_age: filter.end_age,
          start_date: filter.start,
          end_date: filter.end,
        )
    end

    private def clients_within_projects
      @clients_within_projects ||= begin
        GrdaWarehouse::Hud::Client.destination.joins(service_history_enrollments: :project).
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

    private def filter_for_sub_population(clients)
      clients.joins(:service_history_enrollments).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.homeless.public_send(filter.sub_population))
    end

    def yes_no(bool)
      bool ? 'Yes' : 'No'
    end
  end
end
