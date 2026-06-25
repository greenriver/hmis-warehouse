###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::Enrollment
  class AddNewColumns
    def process(row)
      row['MentalHealthConsultation'] = nil

      row
    end
  end
end
