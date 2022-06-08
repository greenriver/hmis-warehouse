###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TEMPORARY: example of a POST request for testing HMIS authentication. Replace with GraphQL endpoint!

class HmisApi::ProjectsController < HmisApi::BaseController
  include ArelHelper
  respond_to :json

  def index
    render json: project_scope.pluck(:ProjectName)
  end

  private def project_types
    return HUD.project_types.keys unless project_params[:project_types].present?

    @project_types ||= begin
      types = []

      project_type_to_id = project_source::PERFORMANCE_REPORTING.merge(project_source::RESIDENTIAL_PROJECT_TYPES)
      if project_params[:project_types].present?
        project_params[:project_types]&.select(&:present?)&.map(&:to_sym)&.each do |type|
          types += project_type_to_id[type]
        end
      end
      types
    end
  end

  def project_params
    params.permit(
      project_types: [],
    )
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  private def project_scope
    project_source.viewable_by(current_hmis_api_user).with_project_type(project_types).distinct
  end
end
