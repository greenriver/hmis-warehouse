###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  TbraLongevityFilter = Struct.new(:label, :client_ids, keyword_init: true) do
    def apply(scope)
      scope.where(destination_client_id: client_ids)
    end

    # interpreting the spec as measuring years since the earliest entry-date for a hopwa-qualified individual
    def self.for_report(report)
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa

      rows = program_filter.apply(report.hopwa_caper_enrollments).
        where(hopwa_eligible: true).
        group(:destination_client_id).
        pluck(:destination_client_id, Arel.sql('MIN(entry_date)'))

      buckets = {
        'less than one year' => [],
        'more than one year, but less than five years' => [],
        'more than five years, but less than 10 years' => [],
        'more than 10 years, but less than 15 years' => [],
        'more than 15 years' => [],
      }
      rows.each do |client_id, entry_date|
        years_diff = ((report.end_date - entry_date) / 365.25).to_i
        if years_diff == 0
          bucket = 'less than one year'
        elsif years_diff.between?(1, 5)
          bucket = 'more than one year, but less than five years'
        elsif years_diff.between?(6, 10)
          bucket = 'more than five years, but less than 10 years'
        elsif years_diff.between?(10, 15)
          bucket = 'more than 10 years, but less than 15 years'
        elsif years_diff > 15
          bucket = 'more than 15 years'
        end
        buckets[bucket].push(client_id)
      end

      filters = buckets.map do |label, client_ids|
        new(label: "How many households have been served with TBRA for #{label}?", client_ids: client_ids)
      end
      total_filter = new(
        label: 'Longevity for Households Served by this Activity',
        client_ids: buckets.values.flatten,
      )
      [total_filter] + filters
    end
  end
end
