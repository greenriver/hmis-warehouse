###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# delete file
module Censuses
  class Base
    include Filter::ControlSections

    def initialize(filter)
      @filter = filter
    end

    def self.available_census_types
      [
        Censuses::CensusByProgram,
        Censuses::CensusByProjectType,
        Censuses::CensusVeteran,
      ]
    end

    private def build_control_sections
      []
    end
  end
end
