###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###


module HudTwentyTwentyToTwentyTwentyTwo::Client
  class TransformGenderToColumns
    def process(row)
      # Default values
      female = 0
      male = 0
      no_single_gender = 0
      transgender = 0
      questioning = 0
      gender_none = nil

      # Override default values based on 2020 Gender
      # This is pending HUD guidance
      case row['Gender']&.to_s
      when '0'
        female = '1'
      when '1'
        male = '1'
      when '2'
        female = '1'
        transgender = '1'
      when '3'
        male = '1'
        transgender = '1'
      when '4'
        no_single_gender = '1'
      when '8', '9', '99', nil
        gender_none = row['Gender']
      end

      row['Female'] = female
      row['Male'] = male
      row['NoSingleGender'] = no_single_gender
      row['Transgender'] = transgender
      row['Questioning'] = questioning
      row['GenderNone'] = gender_none

      row
    end
  end
end
