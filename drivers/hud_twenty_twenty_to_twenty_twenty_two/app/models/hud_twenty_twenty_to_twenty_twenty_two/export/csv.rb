###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyToTwentyTwentyTwo::Export
  class Csv < Transforms
    include HudTwentyTwentyToTwentyTwentyTwo::Kiba::CsvBase
  end
end
