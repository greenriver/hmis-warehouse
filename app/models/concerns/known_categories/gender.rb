###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Gender
  extend ActiveSupport::Concern

  def gender_calculations
    @gender_calculations ||= {}.tap do |calcs|
      HUD.genders.each do |key, title|
        field = HUD.gender_id_to_field_name[key]
        next if field == :GenderNone

        calcs[title] = ->(value) { value == 1 }
      end
      calcs['Client doesn\'t know'] = ->(value) { value == 8 }
      calcs['Client refused'] = ->(value) { value == 9 }
      calcs['Data not collected'] = ->(value) { value == 99 }
    end
  end

  def standard_gender_calculation
    # See LSA for calculation logic
    conditions = [
      [c_t[:GenderNone].eq(8), 8],
      [c_t[:GenderNone].eq(9), 9],
      [c_t[:Questioning].eq(1), 5],
      [c_t[:NoSingleGender].eq(1), 4],
      [c_t[:Female].eq(1).and(c_t[:Male].eq(1)), 4],
      [c_t[:Transgender].eq(1), 3],
      [c_t[:Female].eq(1), 1],
      [c_t[:Male].eq(1), 2],
    ]
    acase(conditions, elsewise: 99)
  end
end
