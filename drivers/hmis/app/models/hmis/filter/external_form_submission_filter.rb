###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::ExternalFormSubmissionFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    byebug
    date_range = input.submitted_date&.then { |date| [date.beginning_of_day..date.end_of_day] }
    scope = scope.where(submitted_at: date_range) if date_range
    scope = scope.where(status: input.status) if input.status
    scope
  end
end
