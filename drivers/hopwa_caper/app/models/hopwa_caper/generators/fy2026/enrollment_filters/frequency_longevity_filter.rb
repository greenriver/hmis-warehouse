# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  # Buckets enrollments by number of distinct service years in the 5-year window ending at end_date.
  # Intended for STRMU frequency reporting, where each service event is a separate enrollment.
  #
  # "Years of service" are approximated by calendar year (EXTRACT(YEAR FROM entry_date)), not
  # reporting periods. Since HOPWA reporting periods are federal fiscal years (Oct–Sep), calendar
  # years are an inherent approximation regardless of window boundaries. The (end_date - 5.years)
  # window is the natural anchor and consistent with how clients/funders reason about history.
  #
  # Per-row GREATEST(entry_date, funder.start_date) avoids crediting service years that predate
  # HOPWA funding for that enrollment, unlike EnrollmentLongevityFilter which uses a single
  # aggregate GREATEST(MIN(entry_date), MIN(start_date)) across a client's full history.
  FrequencyLongevityFilter = Data.define(:label, :criterion, :end_date, :start_date, :funder_codes, :reference_scope) do
    def apply(scope)
      return scope if criterion.nil?

      tenure_year = Arel.sql('EXTRACT(YEAR FROM GREATEST(entry_date, start_date))')

      # Funders join ensures we only count years when relevant funding was active.
      subquery = reference_scope.
        joins(:funders).
        merge(HopwaCaper::Funder.where(code: funder_codes)).
        where(entry_date: (end_date - 5.years)..end_date).
        group(:destination_client_id)

      case criterion
      when :consecutive_5_years
        subquery = subquery.having("COUNT(DISTINCT #{tenure_year}) >= 5")
      when :more_than_twice_5_years
        subquery = subquery.having("COUNT(DISTINCT #{tenure_year}) BETWEEN 3 AND 4")
      when :previous_year
        subquery = subquery.having("COUNT(DISTINCT #{tenure_year}) <= 2 AND MIN(entry_date) < ?", start_date)
      when :first_time
        subquery = subquery.having("COUNT(DISTINCT #{tenure_year}) = 1 AND MIN(entry_date) >= ?", start_date)
      end

      scope.where(destination_client_id: subquery.select(:destination_client_id))
    end

    def self.all(activity_label:, end_date:, start_date:, funder_codes:, reference_scope:)
      labels = {
        first_time: "How many households have been served by #{activity_label} for the first time this year?",
        previous_year: "How many households also received #{activity_label} assistance during the previous #{activity_label} eligibility period?",
        more_than_twice_5_years: "How many households received #{activity_label} assistance more than twice during the previous five eligibility periods?",
        consecutive_5_years: "How many households received #{activity_label} assistance during the last five consecutive eligibility periods?",
      }

      filters = labels.map do |criterion, label|
        new(label: label, criterion: criterion, end_date: end_date, start_date: start_date, funder_codes: funder_codes, reference_scope: reference_scope)
      end

      total = new(label: 'Longevity for Households Served by this Activity', criterion: nil, end_date: end_date, start_date: start_date, funder_codes: funder_codes, reference_scope: reference_scope)
      [total] + filters
    end
  end
end
