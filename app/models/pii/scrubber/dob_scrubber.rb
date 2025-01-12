###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

module Pii::Scrubber
  class DobScrubber
    def perform(fields)
      dob_fields = fields.filter { |f| f.type == :dob }

      dob_fields.each do |dob_field|
        real_dob = parse_date(dob_field.real_value)
        dob_field.scrub(scramble_dob(real_dob))
      end

      # If there's one dob field, try and adjust ages to correspond
      dob_field = dob_fields.size == 1 ? dob_fields.first : nil
      return unless dob_field

      age_fields = fields.filter { |f| f.type == :age }
      age_fields.each do |age_field|
        age_value = dob_field.scrubbed_value ? age_in_years(dob_field.scrubbed_value) : age_field.real_value
        age_field.scrub(age_value)
      end
    end

    protected

    # not current scrubbing age unless accompanied by DOB
    # def scramble_age(current, fuzz_years: 5)
    #   return nil unless current

    #   new_dob = scramble_dob(today - current, fuzz_years: fuzz_years)
    #   (today - new_dob).years
    # end

    # Scrambles a date of birth while preserving approximate age bracket of the original
    # For example, with a 5-year bracket, someone aged 32 will get a DOB corresponding to age 30-35.
    def scramble_dob(current, fuzz_years: 5)
      return nil unless current

      age_at_scrub = age_in_years(current)
      age_bracket = (age_at_scrub / fuzz_years) * fuzz_years # Creates brackets
      bracket_end = [today - age_bracket.years, today].min
      bracket_start = today - (age_bracket + fuzz_years).years

      Faker::Date.between(from: bracket_start, to: bracket_end)
    end

    def age_in_years(dob)
      ((today - dob) / 365.25).floor
    end

    def parse_date(value)
      return value unless value.is_a?(String)

      begin
        Date.strptime(value, '%Y-%m-%d')
      rescue ArgumentError
        nil
      end
    end

    def today
      @today ||= Date.current
    end
  end
end
