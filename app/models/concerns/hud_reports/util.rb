###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports::Util
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  included do
    # Earlier enrollments for the same client in the same project where this project start date
    # falls between the earlier project start date and the earlier project exit date. The spec does
    # not mention what to do when the earlier enrollment has no exit date, so we  mimics the DataLab
    # implementation of the overlapping enrollments calculation by dropping enrollments with no exit date.
    private def overlapping_enrollments(enrollments, last_enrollment)
      enrollments.select do |enrollment|
        next false if enrollment.id == last_enrollment.id
        next false unless enrollment.data_source_id == last_enrollment.data_source_id
        next false unless enrollment.project_id == last_enrollment.project_id
        next false if enrollment.last_date_in_program.blank?

        enrollment.first_date_in_program < last_enrollment.first_date_in_program &&
          last_enrollment.first_date_in_program < enrollment.last_date_in_program
      end.map(&:enrollment_group_id).uniq
    end

    # APR/CAPER PIT dates are defined to be the LAST WEDNESDAY of the most recent specified month before the end of
    # the reporting period (So, for example if a report ends in the middle of August, A date between Jan - Jul would
    # fall in the same year as the report end date, and Aug - Dec would fall in the previous year).
    def pit_date(month:, before:)
      # Months prior to the before date are in the same year
      year = before.year if month < before.month
      # Days in the before month fall in the same year if the before date is on or after the PIT date
      year = before.year if month == before.month && before.day >= last_wednesday_of(month: before.month, year: before.year).day
      # Months after the before date are in the previous year
      year = before.year - 1 if month > before.month
      # Days in the before month fall in the previous year if the before date is before the PIT date
      year = before.year - 1 if month == before.month && before.day < last_wednesday_of(month: before.month, year: before.year).day

      last_wednesday_of(month: month, year: year)
    end

    private def last_wednesday_of(month:, year:)
      date = Date.new(year, month, 1).end_of_month
      return date if date.wednesday?

      date.prev_occurring(:wednesday)
    end

    private def anniversary_date(entry_date:, report_end_date:)
      enrollment_age = report_end_date.year - entry_date.year
      enrollment_age -= 1 if entry_date > report_end_date.years_ago(enrollment_age)
      entry_date + enrollment_age.years
    end

    private def percentage(value)
      value = 0 if value.to_f.nan?

      format('%1.4f', value.round(4))
    end

    private def money(value)
      format('%.2f', number_with_precision(value, precision: 2, round_mode: :banker))
    end
  end

  # given a column (letter), return the next col in sequence
  # A => B, Z => AA, etc
  def self.next_column_identifier(column)
    # Convert the column to an integer
    n = 0
    column.each_char do |char|
      n = n * 26 + (char.ord - 65 + 1) # 65 is the ASCII code for 'A', add 1 for 1-based indexing
    end

    # Increment the integer and convert it back to an identifier
    n += 1
    result = ''
    while n.positive?
      remainder = (n - 1) % 26 # Subtracting 1 to handle 1-based indexing
      result = (65 + remainder).chr + result # 65 is the ASCII code for 'A'
      n = (n - 1) / 26 # Subtracting 1 to handle 1-based indexing
    end

    result
  end
end
