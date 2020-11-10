###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class ProjectPassFail < GrdaWarehouseBase
    self.table_name = :project_pass_fails
    include Filter::ControlSections
    include Filter::FilterScopes

    def initialize(filter)
      @filter = filter
    end

    def title
      'Project Pass/Fail Report'
    end

    def url
      project_pass_fail_warehouse_reports_project_pass_fail_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
    end
  end
end
