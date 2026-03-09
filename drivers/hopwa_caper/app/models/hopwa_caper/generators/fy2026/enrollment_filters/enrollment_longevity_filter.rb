# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  # Buckets enrollments by years of continuous service, measured from
  # GREATEST(MIN(entry_date), MIN(start_date)) to the report end_date.
  # reference_scope should be an undated enrollment scope so prior-period service counts toward longevity.
  # date_range bounds are exclusive-lower / inclusive-upper (nil = unbounded).
  EnrollmentLongevityFilter = Struct.new(:label, :date_range, :reference_scope, keyword_init: true) do
    def apply(scope)
      return scope if date_range.nil?

      # The joins(:funders) ensures we only count tenure starting from when
      # HOPWA funding actually began for this enrollment/client.
      # Longevity starts from GREATEST(client's earliest entry_date, funder's earliest start_date).
      earliest_date = Arel.sql('GREATEST(MIN(entry_date), MIN(start_date))')
      subquery = reference_scope.group(:destination_client_id).joins(:funders)
      subquery = subquery.having("#{earliest_date} > ?", date_range.begin) if date_range.begin
      subquery = subquery.having("#{earliest_date} <= ?", date_range.end) if date_range.end
      scope.where(destination_client_id: subquery.select(:destination_client_id))
    end

    def self.all(activity_label:, end_date:, reference_scope:)
      filters = [
        new(label: "How many households have been served with #{activity_label} for less than one year?", date_range: (end_date - 1.year).., reference_scope: reference_scope),
        new(label: "How many households have been served with #{activity_label} for more than one year, but less than five years?", date_range: (end_date - 5.years)..(end_date - 1.year),   reference_scope: reference_scope),
        new(label: "How many households have been served with #{activity_label} for more than five years, but less than 10 years?", date_range: (end_date - 10.years)..(end_date - 5.years), reference_scope: reference_scope),
        new(label: "How many households have been served with #{activity_label} for more than 10 years, but less than 15 years?",   date_range: (end_date - 15.years)..(end_date - 10.years), reference_scope: reference_scope),
        new(label: "How many households have been served with #{activity_label} for more than 15 years?", date_range: ..(end_date - 15.years), reference_scope: reference_scope),
      ]
      total = new(label: 'Longevity for Households Served by this Activity', date_range: nil, reference_scope: reference_scope)
      [total] + filters
    end
  end
end
