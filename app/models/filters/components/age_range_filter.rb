module Filters::Components
  AgeRangeFilter = Struct.new(:label, :age_ranges, keyword_init: true) do
    def apply(scope)
      # Or'ing ages is very slow, instead we'll build up an acceptable
      # array of ages
      ages = age_ranges.flat_map do |age_range|
        Filters::FilterBase.age_range(age_range).to_a
      end
      scope.joins(join_clients_method).where(age_calculation.in(ages))
    end

    # This method can be used to generate the select for a client's age at entry or start date (usually report start)
    # It requires the query to include both Client and ServiceHistoryEnrollment to function
    private def age_on_date(start_date)
      cast(
        datepart(
          GrdaWarehouse::ServiceHistoryEnrollment,
          'YEAR',
          nf('AGE', [nf('GREATEST', [she_t[:first_date_in_program], start_date]), c_t[:DOB]]),
        ),
        'integer',
      )
    end
  end
end
