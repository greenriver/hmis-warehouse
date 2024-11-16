###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module GrdaWarehouse::Tasks::ScrubPii
  class DobScrubber
    def initialize(seed: nil)
      Faker::Config.random = Random.new(seed) if seed
    end

    def perform(fields)
      dob_field = fields.detect { |f| f.type == :dob}
      if dob_field
        dob_value = scramble_dob(dob_field.raw_value)
        field.scrub(dob_value)
      end

      dob_field = fields.detect { |f| f.type == :age }
      if age_field
        age_value = age_field.raw_value
        age_value = dob_value ? today - dob_value : scramble_age(age_value)
        field.scrub(age_value)
      end
    end

    protected

    def scramble_age(current, fuzz_years: 5)
      return nil unless current

      new_dob = scramble_dob(today - current, fuzz_years: fuzz_years)
      today - new_dob
    end

    # Scrambles a date of birth while preserving approximate age bracket of the original
    # For example, with a 5-year bracket, someone aged 32 will get a DOB corresponding to age 30-35.
    def scramble_dob(current, fuzz_years: 5)
      return nil unless current

      age_at_scrub = ((today - current) / 365.25).floor
      age_bracket = (age_at_scrub / fuzz_years) * fuzz_years # Creates brackets
      bracket_end = [today - age_bracket.years, today].min
      bracket_start = today - (age_bracket + fuzz_years).years

      Faker::Date.between(from: bracket_start, to: bracket_end)
    end

    def today
      @today ||= Date.current
    end
  end
end
