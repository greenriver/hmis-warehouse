###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Client
  class UpdateGenders
    def process(row)
      # Renames
      row['Woman'] = row['Female']
      row['Man'] = row['Male']
      row['NonBinary'] = row['NoSingleGender']

      # Added, default to No (Not Selected)
      row['CulturallySpecific'] = 0
      row['DifferentIdentity'] = 0
      row['DifferentIdentityText'] = nil

      row
    end
  end
end
