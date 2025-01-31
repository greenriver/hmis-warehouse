###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ImportThresholdsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :data_source
  before_action :import_threshold

  def show
  end

  def update
    import_threshold.update!(import_threshold_params)
    respond_with(import_threshold, location: data_source_import_threshold_path)
  end

  private def import_threshold_params
    params.require(:grda_warehouse_import_threshold).
      permit(*GrdaWarehouse::ImportThreshold.known_params)
  end

  private def data_source_scope
    GrdaWarehouse::DataSource.viewable_by(current_user, permission: :can_view_projects)
  end

  private def data_source
    @data_source ||= data_source_scope.find_safely(params[:data_source_id])
  end
  helper_method :data_source

  # Ensure the import threshold is saved so the related notifications can be added
  private def import_threshold
    @import_threshold ||= data_source.import_threshold || GrdaWarehouse::ImportThreshold.create!(data_source_id: data_source.id)
  end
  helper_method :import_threshold
end
