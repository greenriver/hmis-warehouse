###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  TbraLongevityFilter = Struct.new(:label, :personal_ids, keyword_init: true) do
    def apply(scope)
      scope.where(personal_id: personal_ids)
    end

    def self.for_report(report)
      report.start_date
      end_date = report.end_date

      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa

      # measure from the earliest entry date for this individual
      grouped = program_filter.apply(report.hopwa_caper_enrollments).
        where(hopwa_eligible: true).
        group(:personal_id).
        pluck(:personal_id, Arel.sql('MIN(entry_date)')).to_h

      buckets = {
        'less than one year' => [],
        'more than one year, but less than five years' => [],
        'more than five years, but less than 10 years' => [],
        'more than 10 years, but less than 15 years' => [],
        'more than 15 years' => [],
      }
      grouped.each do |personal_id, entry_date|
        years_diff = ((end_date - entry_date) / 365.25).to_i
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
        buckets[bucket].push(personal_id)
      end

      buckets.map do |label, personal_ids|
        new(label: "How many households have been served with TBRA for #{label}?", personal_ids: personal_ids)
      end
    end
  end
end
