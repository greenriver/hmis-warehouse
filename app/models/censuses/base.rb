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