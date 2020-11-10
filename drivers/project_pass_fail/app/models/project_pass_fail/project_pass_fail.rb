###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class ProjectPassFail
    include Filter::ControlSections
    include Filter::FilterScopes

    def initialize(filter)
      @filter = filter
    end

    def title
      'Project Pass/Fail Report'
    end

    def url
      warehouse_reports_health_encounters_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
    end
  end
end
