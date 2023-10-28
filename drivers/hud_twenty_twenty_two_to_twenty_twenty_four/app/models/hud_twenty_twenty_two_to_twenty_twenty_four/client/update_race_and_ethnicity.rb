###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::Client
  class UpdateRaceAndEthnicity
    def process(row)
      row['HispanicLatinaeo'] = row['Ethnicity'] == 1 ? 1 : 0 # 8/9/99 all convert to 0
      row['RaceNone'] = nil if row['HispanicLatinaeo'] == 1 # Force clearing of RaceNone if we set HispanicLatinaeo

      # Added fields
      row['MidEastNAfrican'] = 0
      row['AdditionalRaceEthnicity'] = nil

      # No race can be 99 or blank
      row['Asian'] = 0 if row['Asian'].in?([99, nil])
      row['BlackAfAmerican'] = 0 if row['BlackAfAmerican'].in?([99, nil])
      row['NativeHIPacific'] = 0 if row['NativeHIPacific'].in?([99, nil])
      row['White'] = 0 if row['White'].in?([99, nil])

      row
    end
  end
end
