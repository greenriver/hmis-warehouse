###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour::CeParticipation
  class Db < Transforms
    include HudTwentyTwentyTwoToTwentyTwentyFour::Kiba::DbBase

    def self.source_class
      Kiba::Common::Sources::Enumerable
    end
  end
end
