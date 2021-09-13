###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

    # in the form [{project_name: 'Project Name', date: 'last date', project_id: 'Project ID}]
    cohort_client.client.processed_service_history.public_send(column).
      select do |row|
        row['project_id'].in? user.visible_project_ids_enrollment_context
      end.
      sort do |a, b|
        b['date'].to_date <=> a['date'].to_date
      end.
      map do |row|
        "#{row['project_name']}: #{row['date']}"
      end.join('; ')
  end
end
