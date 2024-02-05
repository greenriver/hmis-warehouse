###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

      # No gender can be 99 or blank
      row['Woman'] = 0 if row['Woman'].in?([99, nil])
      row['Man'] = 0 if row['Man'].in?([99, nil])
      row['NonBinary'] = 0 if row['NonBinary'].in?([99, nil])
      row['Transgender'] = 0 if row['Transgender'].in?([99, nil])
      row['Questioning'] = 0 if row['Questioning'].in?([99, nil])

      row
    end
  end
end
