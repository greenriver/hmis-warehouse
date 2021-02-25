###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CensusTracking
  class Worksheet
    def initialize(filter)
      @filter = filter
    end

    def projects
      []
    end

    def clients_by_project(_project_id, _query)
      []
    end

    def clients_by_project_type(_project_type, _query)
      []
    end

    def clients_by_population(_query)
      []
    end

    def populations
      @populations ||= {
        'Unaccompanied Males Under Age 18' => nil,
        'Unaccompanied Females Under Age 18' => nil,
        'Single Adult Males Age 18-24' => nil,
        'Single Adult Females Age 18-24' => nil,
        'Single Adult Males Age 25+' => nil,
        'Single Adult Females Age 25+' => nil,
        'Number of Families with at least one adult age 18+ and at least one child under age 18' => nil,
        'Number of Families with all members under age 18' => nil,
        'Number of children under age 18 in all families served' => nil,
        'Number of adults age 18-24 in all families served' => nil,
        'Number of adults age 25+ in all families served' => nil,
        'Total PIT (including clients of unknown gender)' => nil,
      }
    end
  end
end
