###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  # STRMU is one-time service. Expect a new enrollment/household every time so we count individuals
  StrmuLongevityFilter = Struct.new(:label, :personal_ids, keyword_init: true) do
    def apply(scope)
      scope.where(personal_id: personal_ids)
    end

    def self.for_report(report)
      start_date = report.start_date
      year_offset = start_date.yday - 1 # days since jan 1
      end_date = report.end_date

      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa

      grouped = program_filter.apply(report.hopwa_caper_enrollments).
        where(hopwa_eligible: true).
        where(entry_date: (start_date - 5.years)..end_date).
        group(:personal_id).
        pluck(:personal_id, Arel.sql('ARRAY_AGG(entry_date)')).to_h

      buckets = {
        new: [],
        prev: [],
        three_or_more: [],
        all_five: [],
      }

      current_year = start_date.year
      grouped.each do |personal_id, entry_dates|
        entry_years = entry_dates.map { |d| (d - year_offset).year }.uniq
        if entry_years == [current_year]
          buckets[:new] << personal_id
          next
        end

        buckets[:prev] << personal_id if entry_years.include?(current_year - 1)
        buckets[:three_or_more] << personal_id if entry_years.size > 2
        buckets[:all_five] << personal_id if entry_years.size == 5
      end

      [
        new(
          label: 'How many households have been served by STRMU for the first time this year?',
          personal_ids: buckets[:new],
        ),
        new(
          label: 'How many households also received STRMU assistance during the previous year?',
          personal_ids: buckets[:prev],
        ),
        new(
          label: 'How many households received STRMU assistance more than twice during the previous five years?',
          personal_ids: buckets[:three_or_more],
        ),
        new(
          label: 'How many households received STRMU assistance during the last five consecutive years?',
          personal_ids: buckets[:all_five],
        ),
      ]
    end
  end
end
