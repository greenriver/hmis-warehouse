###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SyntheticCeAssessments
  class ProjectConfigController < ApplicationController
    before_action :require_can_edit_projects!
    before_action :project
    before_action :project_config

    # If we don't have one, create it and redirect to edit
    def new
      redirect_to edit_synthetic_ce_assessments_project_config_path(project_config, project_id: project.id)
    end

    def edit
    end

    def update
      project_config.update(permitted_params)
      respond_with(project_config, location: edit_synthetic_ce_assessments_project_config_path(project_config, project_id: project.id))
    end

    private def permitted_params
      params.require(:synthetic_ce_assessment_project_config).
        permit(
          :active,
          :assessment_type,
          :assessment_level,
          :prioritization_status,
        )
    end

    private def project_scope
      project_source.viewable_by(current_user, confidential_scope_limiter: :all, permission: :can_edit_projects)
    end

    private def project_source
      GrdaWarehouse::Hud::Project
    end

    private def project
      @project ||= project_scope.find(params[:project_id].to_i)
    end

    private def project_config
      @project_config ||= project.synthetic_ce_project_config
      return @project_config if @project_config.present?

      @project_config = project.create_synthetic_ce_project_config(assessment_type: 2, assessment_level: 1, prioritization_status: 2)
    end
  end
end
