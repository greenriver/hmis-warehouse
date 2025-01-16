###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ImportThresholdsController < ApplicationController
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :data_source
  before_action :import_threshold

  def show
  end

  def update
    error = false
    begin
      @data_source.update!(data_source_params)
    rescue StandardError => e
      error = true
    end
    if error
      flash[:error] = "Unable to update data source. #{e}"
      render :show
    else
      redirect_to data_source_path(@data_source), notice: 'Data Source updated'
    end
  end

  private def import_threshold_params
    params.require(:import_threshold).
      permit(*GrdaWarehouse::ImportThreshold.known_params)
  end

  private def data_source_source
    GrdaWarehouse::DataSource.viewable_by(current_user, permission: :can_view_projects)
  end

  private def data_source_scope
    data_source_source.source
  end

  private def data_source
    @data_source ||= data_source_source.find(params[:data_source_id].to_i)
  end

  private def import_threshold
    @import_threshold ||= data_source.import_threshold || GrdaWarehouse::ImportThreshold.new(data_source_id: data_source.id)
  end
end
