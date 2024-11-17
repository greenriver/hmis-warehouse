###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module GrdaWarehouse::Tasks::ScrubPii
  class DobScrubber
    def perform(fields)
      dob_field = fields.detect { |f| f.type == :dob }
      real_dob = dob_field&.real_value
      dob_field.scrub(scramble_dob(real_dob)) if real_dob

      age_field = fields.detect { |f| f.type == :age }
      real_age = age_field&.real_value
      return unless real_age

      age_value = age_in_years(dob_field.scrubbed_value || scramble_dob(today - real_age.years))
      age_field.scrub(age_value)
    end

    protected

    def age_in_years(dob)
      age = today.year - dob.year
      age -= 1 if today < dob + age.years
      age
    end

    def scramble_age(current, fuzz_years: 5)
      return nil unless current

      new_dob = scramble_dob(today - current, fuzz_years: fuzz_years)
      (today - new_dob).years
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
