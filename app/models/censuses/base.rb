###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class Base
    def self.available_census_types
      [
        Censuses::CensusBedNightProgram,
        Censuses::CensusAllEs,
        Censuses::CensusAllSo,
        Censuses::CensusByProgram,
        Censuses::CensusByProjectType,
        Censuses::CensusVeteran,
      ]
    end
  end
end
