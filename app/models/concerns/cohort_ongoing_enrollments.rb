###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortOngoingEnrollments
  extend ActiveSupport::Concern

  def value_requires_user?
    true
  end

  def display_read_only(user)
    value(cohort_client, user)
  end

  private def for_display(column, user)
    return nil unless cohort_client.client.processed_service_history&.public_send(column)

    enforce_visibility = cohort_client.cohort.enforce_project_visibility_on_cells?
    window_project_ids = GrdaWarehouse::Hud::Project.joins(:data_source).
      merge(GrdaWarehouse::DataSource.visible_in_window).
      pluck(:id)
    # in the form [{project_name: 'Project Name', date: 'last date', project_id: 'Project ID}]
    cohort_client.client.processed_service_history.public_send(column).
      select do |row|
        next row['project_id'].in?(user.visible_project_ids_enrollment_context) if enforce_visibility
        next true unless cohort.only_window?

        row['project_id'].in?(window_project_ids)
      end.
      sort do |a, b|
        b['date'].to_date <=> a['date'].to_date
      end.
      map do |row|
        "#{row['project_name']}: #{row['date']}"
      end.join('; ')
  end
end
