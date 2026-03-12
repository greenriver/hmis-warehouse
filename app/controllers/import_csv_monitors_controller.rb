###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ImportCsvMonitorsController < ApplicationController
  before_action :require_can_view_imports_projects_or_organizations!
  before_action :data_source
  before_action :import_csv_monitor, only: [:edit, :update, :destroy]

  helper_method :import_csv_monitor

  def index
    redirect_to data_source_import_threshold_path(data_source)
  end

  def new
    @import_csv_monitor = data_source.import_csv_monitors.build
  end

  def create
    @import_csv_monitor = data_source.import_csv_monitors.build(import_csv_monitor_params)
    if @import_csv_monitor.save
      redirect_to data_source_import_threshold_path(data_source), notice: 'Monitor created.'
    else
      flash[:error] = @import_csv_monitor.errors.messages.values.flatten.uniq.join('<br />').html_safe
      render :new
    end
  end

  def edit
  end

  def update
    if import_csv_monitor.update(import_csv_monitor_params)
      redirect_to data_source_import_threshold_path(data_source), notice: 'Monitor updated.'
    else
      flash[:error] = import_csv_monitor.errors.messages.values.flatten.uniq.join('<br />').html_safe
      render :edit
    end
  end

  def destroy
    import_csv_monitor.destroy!
    redirect_to data_source_import_threshold_path(data_source), notice: 'Monitor removed.'
  end

  private def data_source
    @data_source ||= GrdaWarehouse::DataSource.viewable_by(
      current_user,
      permission: :can_view_projects,
    ).find(params[:data_source_id])
  end
  helper_method :data_source

  private def import_csv_monitor
    return unless params[:id].present?

    @import_csv_monitor ||= data_source.import_csv_monitors.find(params[:id])
  end

  private def import_csv_monitor_params
    params.require(:grda_warehouse_import_csv_monitor).permit(
      :csv_file_name,
      :count_increase_threshold,
      :count_decrease_threshold,
      :min_additions_threshold,
      :max_removals_threshold,
      :active,
    )
  end
end
