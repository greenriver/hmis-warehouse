###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Client
  class TransformRace
    def process(row)
      row['NativeHIPacific'] = row['NativeHIOtherPacific']

      row
    end
  end
end
