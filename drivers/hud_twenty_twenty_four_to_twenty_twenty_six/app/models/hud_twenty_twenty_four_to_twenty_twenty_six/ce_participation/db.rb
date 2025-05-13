###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyFourToTwentyTwentySix::CeParticipation
  class Db < Transforms
    include HudTwentyTwentyFourToTwentyTwentySix::Kiba::DbBase

    def self.source_class
      Kiba::Common::Sources::Enumerable
    end
  end
end
