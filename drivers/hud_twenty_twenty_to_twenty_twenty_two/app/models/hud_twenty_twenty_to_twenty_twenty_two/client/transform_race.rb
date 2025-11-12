###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Client
  class TransformRace
    def process(row)
      row['NativeHIPacific'] = row['NativeHIOtherPacific']

      row
    end
  end
end
