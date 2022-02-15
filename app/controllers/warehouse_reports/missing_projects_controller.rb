###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class MissingProjectsController < ApplicationController
    include WarehouseReportAuthorization
    def index
      enrollment_projects = enrollment_source.distinct.select(:ProjectID, :data_source_id).pluck(:ProjectID, :data_source_id)
      projects = project_source.distinct.select(:ProjectID, :data_source_id).pluck(:ProjectID, :data_source_id)
      missing_projects = enrollment_projects - projects
      data_sources = data_source_source.pluck(:id, :name).to_h
      @enrollments = enrollment_source.where(ProjectID: missing_projects.map(&:first)).where(data_source_id: missing_projects.map(&:second))
      @newest = @enrollments.maximum(:EntryDate)
      @projects = missing_projects.map { |m| { project_id: m.first, data_source_id: m.last, data_source_name: data_sources[m.last] } }
    end

    private def project_source
      GrdaWarehouse::Hud::Project
    end

    private def enrollment_source
      GrdaWarehouse::Hud::Enrollment
    end

    private def data_source_source
      GrdaWarehouse::DataSource
    end
  end
end
