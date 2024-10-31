###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  # STRMU is one-time service. Expect a new enrollment/household every time service is provided
  StrmuLongevityFilter = Struct.new(:label, :client_ids, keyword_init: true) do
    def apply(scope)
      scope.where(destination_client_id: client_ids)
    end

    def self.for_report(report)
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa

      rows = program_filter.apply(report.hopwa_caper_enrollments).
        where(hopwa_eligible: true).
        where(entry_date: (report.start_date - 5.years)..report.end_date).
        group(:destination_client_id).
        pluck(:destination_client_id, Arel.sql('ARRAY_AGG(entry_date)'))

      # since the report asks us to sum these, assume they are expected mutually exclusive
      buckets = {
        'How many households have been served by STRMU for the first time this year?' => [],
        'How many households also received STRMU assistance during the previous year?' => [],
        'How many households received STRMU assistance more than twice during the previous five years?' => [],
        'How many households received STRMU assistance during the last five consecutive years?' => [],
      }

      current_year = report.end_date.year
      service_years = (0..4).map { |i| current_year - i }
      rows.each do |client_id, entry_dates|
        # what years are covered by prior enrollments
        entry_years = entry_dates.map(&:year).to_set
        years_served = service_years.count do |service_year|
          service_year.in?(entry_years)
        end

        bucket = nil
        if years_served >= 5
          bucket = 'How many households received STRMU assistance during the last five consecutive years?'
        elsif years_served > 2
          bucket = 'How many households received STRMU assistance more than twice during the previous five years?'
        elsif entry_dates.min < report.start_date
          bucket = 'How many households also received STRMU assistance during the previous year?'
        elsif entry_dates.min >= report.start_date
          bucket = 'How many households have been served by STRMU for the first time this year?'
        else
          raise "could not determine bucket for #{client_id}: #{entry_dates.inspect}"
        end
        buckets[bucket] << client_id
      end

      filters = buckets.map do |label, client_ids|
        new(label: label, client_ids: client_ids)
      end
      total = new(
        label: 'Longevity for Households Served by this Activity',
        client_ids: buckets.values.flatten,
      )
      [total] + filters
    end
  end
end
