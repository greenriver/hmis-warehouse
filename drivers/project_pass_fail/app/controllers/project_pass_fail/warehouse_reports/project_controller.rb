###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# (pick universe from any combination of Project Type, CoC Code, Data Source, Organization, Project, Project Group)
# Date Range
# Show:
#   ES/SO/SH/TH (whatever the top level of the universe is)
#     Overall Utilization Rate
#       Show each project
#     UDE total failed project count
#       Show each Project
#     Timeliness Average timeliness
#       Show each Project

module ProjectPassFail::WarehouseReports
  class ProjectController < ApplicationController
    include AjaxModalRails::Controller
    include ArelHelper

    before_action :require_can_view_clients!

    def show
      @report = report_scope.find(params[:project_pass_fail_id].to_i)
      @project = @report.projects.find(params[:id].to_i)
      @clients = @project.clients.preload(client: :destination_client)
    end

    private def report_class
      ProjectPassFail::ProjectPassFail
    end

    private def report_scope
      report_class.viewable_by(current_user)
    end
  end
end
