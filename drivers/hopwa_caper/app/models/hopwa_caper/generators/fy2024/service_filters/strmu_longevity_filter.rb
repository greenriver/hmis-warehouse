###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::ServiceFilters
  StrmuLongevityFilter = Struct.new(:label, :count, :range, :entry_date, keyword_init: true) do
    def having(grouped)
      grouped = grouped.where(date_provided: range).having('COUNT(DISTINCT EXTRACT(YEAR FROM date_provided)) = ?', count)
      grouped = grouped.merge(HopwaCaper::Enrollment.where(entry_date: entry_date)) if entry_date
      grouped
    end

    # FIXME: unsure about my interpretation. The spec refers to 'periods'- assuming these are years
    def self.all(start_date)
      [
        new(
          label: 'How many households have been served by STRMU for the first time this year?',
          count: 1,
          range: (start_date...(start_date + 1.year)),
          entry_date: start_date,
        ),
        new(
          label: 'How many households also received STRMU assistance during the previous year?',
          count: 1,
          range: ((start_date - 1.year)...start_date),
        ),
        new(
          label: 'How many households received STRMU assistance more than twice during the previous five years?',
          count: 3,
          range: ((start_date - 1.year)...start_date - 5.years),
        ),
        new(
          label: 'How many households received STRMU assistance during the last five consecutive years?',
          count: 5,
          range: ((start_date - 1.year)...start_date - 5.years),
        ),
      ]
    end
  end
end
