
class GeographyController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_geography, only: [:update, :edit]
  before_action :set_project, only: [:edit, :update]

  include ArelHelper

  def edit

  end

  def update
    @geography.update(geography_params)
    respond_with @geography, location: project_path(@project)
  end

  private def geography_params
    params.require(:geography).permit(
      :information_date_override,
      :geocode_override,
      :geography_type_override,
    )
  end

  private def geography_scope
    geography_source.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
  end

  private def geography_source
    GrdaWarehouse::Hud::Geography
  end

  private def set_geography
    @geography = geography_source.find(params[:id].to_i)
  end

  private def set_project
    @project = @geography.project
  end

  def flash_interpolation_options
      { resource_name: 'Geography' }
    end
end