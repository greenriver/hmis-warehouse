###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::ServiceFilters
  StrmuLongevityFilter = Struct.new(:label, :year_count, :range, :entry_date, :start_date, keyword_init: true) do
    def having(grouped)
      # Calculate the offset between start_date and the beginning of its year
      # This allows us to adjust for non-calendar year periods
      year_offset = (start_date - start_date.beginning_of_year).to_i

      # This effectively shifts the year boundary to match our start_date
      # EXTRACT(YEAR FROM ...) gives us the year as an integer
      # date_provided - INTERVAL ? DAY subtracts our offset from each date
      # COUNT(DISTINCT ...) ensures we're counting unique years
      grouped = grouped.where(date_provided: range).
        having("COUNT(DISTINCT EXTRACT(YEAR FROM (date_provided - INTERVAL '#{year_offset} DAY'))) = ?", year_count)

      # If an entry_date is specified, further filter the results
      # This is used for first-time recipients in the current year
      grouped = grouped.merge(HopwaCaper::Enrollment.where(entry_date: entry_date)) if entry_date

      grouped
    end

    def self.all(start_date)
      [
        new(
          label: 'How many households have been served by STRMU for the first time this year?',
          year_count: 1,
          range: (start_date...(start_date + 1.year)),
          entry_date: start_date,
          start_date: start_date,
        ),
        new(
          label: 'How many households also received STRMU assistance during the previous year?',
          year_count: 1,
          range: ((start_date - 1.year)...start_date),
          start_date: start_date,
        ),
        new(
          label: 'How many households received STRMU assistance more than twice during the previous five years?',
          year_count: 3,
          range: ((start_date - 5.years)...start_date),
          start_date: start_date,
        ),
        new(
          label: 'How many households received STRMU assistance during the last five consecutive years?',
          year_count: 5,
          range: ((start_date - 5.years)...start_date),
          start_date: start_date,
        ),
      ]
    end
  end
end
