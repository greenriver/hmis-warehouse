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
    params_with_notifications = import_csv_monitor_params
    user_ids = Array(params_with_notifications.delete(:notification_user_ids)).reject(&:blank?)
    @import_csv_monitor = data_source.import_csv_monitors.build(params_with_notifications)
    if @import_csv_monitor.save
      user_ids.each do |user_id|
        GrdaWarehouse::NotificationConfiguration.create!(
          source: @import_csv_monitor,
          user_id: user_id,
          notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
          active: true,
        )
      end
      redirect_to data_source_import_threshold_path(data_source),
                  notice: 'Monitor created.'
    else
      @import_csv_monitor.notification_user_ids = user_ids
      render :new
    end
  end

  def edit
  end

  def update
    if import_csv_monitor.update(import_csv_monitor_params)
      redirect_to data_source_import_threshold_path(data_source),
                  notice: 'Monitor updated.'
    else
      render :edit
    end
  end

  def destroy
    import_csv_monitor.destroy!
    redirect_to data_source_import_threshold_path(data_source),
                notice: 'Monitor removed.'
  end

  private def data_source
    @data_source ||= GrdaWarehouse::DataSource.viewable_by(
      current_user,
      permission: :can_view_projects,
    ).find(params[:data_source_id])
  end
  helper_method :data_source

  private def import_csv_monitor
    @import_csv_monitor ||= if params[:id].present?
      data_source.import_csv_monitors.find(params[:id])
    elsif ['new', 'create'].include?(params[:action])
      data_source.import_csv_monitors.build
    end
  end

  private def import_csv_monitor_params
    params.require(:grda_warehouse_import_csv_monitor).permit(
      :csv_file_name,
      :count_increase_threshold,
      :count_decrease_threshold,
      :percent_increase_threshold,
      :percent_decrease_threshold,
      :active,
      notification_user_ids: [],
    )
  end
end
