###
# Copyright Green River Data Group, Inc.
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
