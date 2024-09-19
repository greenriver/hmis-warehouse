###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  # STRMU is one-time service. Expect a new enrollment/household every time so we count individuals
  # so we count hopwa-qualified individuals instead
  # year: constrain to unique years
  # range: the range within which to count unique years
  # start/end date: from the report
  StrmuLongevityFilter = Struct.new(:label, :year_count, :range, :year_offset, :start_date, :end_date, keyword_init: true) do
    def having(grouped)
      # Calculate the offset between start_date and the beginning of its year
      # This allows us to adjust for non-calendar year periods
      year_offset = (start_date - start_date.beginning_of_year).to_i

      # only look for individuals who where hopwa eligible within the report period
      params = []
      hopwa_eligible_sql = <<~SQL
        BOOL_OR(hopwa_eligible AND entry_date BETWEEN ? AND ?)
      SQL
      params += [start_date, end_date]

      # This effectively shifts the year boundary to match our start_date
      # EXTRACT(YEAR FROM ...) gives us the year as an integer
      # date_provided - INTERVAL ? DAY subtracts our offset from each date
      # COUNT(DISTINCT ...) ensures we're counting unique years
      year_sql = <<~SQL
        COUNT(DISTINCT EXTRACT(YEAR FROM (entry_date - INTERVAL '#{year_offset} DAY'))) = ?
      SQL
      params << year_count

      # only look for individuals who where hopwa eligible within the report date
      grouped.where(entry_date: range).having("#{hopwa_eligible_sql} AND #{year_sql}", *params)
    end

    def self.all(start_date:, end_date:)
      year_offset = (start_date - start_date.beginning_of_year).to_i
      [
        new(
          label: 'How many households have been served by STRMU for the first time this year?',
          year_count: 1,
          range: (start_date...end_date),
          start_date: start_date,
          end_date: end_date,
        ),
        new(
          label: 'How many households also received STRMU assistance during the previous year?',
          year_count: 1,
          range: ((start_date - 1.year)...start_date),
          start_date: start_date,
          end_date: end_date,
        ),
        new(
          label: 'How many households received STRMU assistance more than twice during the previous five years?',
          year_count: 3,
          range: ((start_date - 5.years)...start_date),
          start_date: start_date,
          end_date: end_date,
        ),
        new(
          label: 'How many households received STRMU assistance during the last five consecutive years?',
          year_count: 5,
          range: ((start_date - 5.years)...start_date),
          start_date: start_date,
          end_date: end_date,
        ),
      ]
    end
  end
end
