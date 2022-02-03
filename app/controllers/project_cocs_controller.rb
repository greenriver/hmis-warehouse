###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectCocsController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_project_coc, only: [:show, :update, :edit]
  before_action :set_project, only: [:edit, :update]

  include ArelHelper
  include AjaxModalRails::Controller

  def edit
  end

  def update
    @project_coc.update(project_coc_params)
    respond_with @project_coc, location: project_path(@project)
  end

  private def project_coc_params
    params.require(:project_coc).permit(
      :hud_coc_code,
      :geocode_override,
      :zip_override,
      :geography_type_override,
    )
  end

  private def project_coc_scope
    project_coc_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
  end

  private def project_coc_source
    GrdaWarehouse::Hud::ProjectCoc
  end

  private def set_project_coc
    @project_coc = project_coc_source.find(params[:id].to_i)
  end

  private def set_project
    @project = @project_coc.project
  end

  def flash_interpolation_options
    { resource_name: 'ProjectCoC' }
  end
end
