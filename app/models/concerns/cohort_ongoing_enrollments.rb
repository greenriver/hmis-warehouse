###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortOngoingEnrollments
  extend ActiveSupport::Concern

  private def for_display(column)
    # in the form [['Project Name', 'last date']]
    cohort_client.client.processed_service_history.public_send(column).
      sort do |a, b|
        b.last.to_date <=> a.last.to_date
      end.
      map do |row|
        row.join(': ')
      end.join('; ')
  end
end
