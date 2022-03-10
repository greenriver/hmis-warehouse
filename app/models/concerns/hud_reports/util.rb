###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports::Util
  extend ActiveSupport::Concern

  included do
    private def overlapping_enrollments(enrollments, last_enrollment)
      last_enrollment_end = last_enrollment.last_date_in_program || Date.tomorrow
      enrollments.select do |enrollment|
        enrollment_end = enrollment.last_date_in_program || Date.tomorrow

        enrollment.id != last_enrollment.id && # Don't include the last enrollment
          enrollment.data_source_id == last_enrollment.data_source_id &&
          enrollment.project_id == last_enrollment.project_id &&
          enrollment.first_date_in_program < last_enrollment_end &&
          enrollment_end > last_enrollment.first_date_in_program
      end.map(&:enrollment_group_id).uniq
    end

    def pit_date(month:, before:)
      year = before.year if month < before.month
      year = before.year if month == before.month && before.day >= last_wednesday_of(month: before.month, year: before.year).day
      year = before.year - 1 if month > before.month
      year = before.year - 1 if month == before.month && before.day < last_wednesday_of(month: before.month, year: before.year).day

      last_wednesday_of(month: month, year: year)
    end

    private def last_wednesday_of(month:, year:)
      date = Date.new(year, month, 1).end_of_month
      return date if date.wednesday?

      date.prev_occurring(:wednesday)
    end

    private def percentage(value)
      value = 0 if value.to_f&.nan?

      format('%1.4f', value.round(4))
    end

    private def money(value)
      format('%.2f', value.round(2))
    end
  end
end
