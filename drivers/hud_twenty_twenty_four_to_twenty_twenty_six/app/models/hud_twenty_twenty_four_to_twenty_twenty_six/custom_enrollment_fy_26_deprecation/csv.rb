###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix
  module CustomEnrollmentFy26Deprecation
    class Csv < Transforms
      include HudTwentyTwentyFourToTwentyTwentySix::Kiba::CsvBase
    end
  end
end
