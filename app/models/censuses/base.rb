###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Censuses
  class Base
    def self.available_census_types
      [
        Censuses::CensusBedNightProgram,
        Censuses::CensusByProgram,
        Censuses::CensusByProjectType,
        Censuses::CensusVeteran,
      ]
    end
  end
end
