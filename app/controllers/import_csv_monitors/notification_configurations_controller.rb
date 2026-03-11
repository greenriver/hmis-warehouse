###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ImportCsvMonitors
  class NotificationConfigurationsController < ApplicationController
    include AjaxModalRails::Controller
    before_action :require_can_view_imports_projects_or_organizations!
    before_action :data_source
    before_action :import_csv_monitor

    def new
      @form_url = data_source_import_csv_monitor_notification_configurations_path(
        data_source,
        import_csv_monitor,
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
      )
    end

    def edit
      @form_url = data_source_import_csv_monitor_notification_configuration_path(
        data_source,
        import_csv_monitor,
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
      )
    end

    def create
      notification_configuration.update!(
        notification_configuration_params.merge(
          notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        ),
      )
      respond_with(notification_configuration, location: edit_data_source_import_csv_monitor_path(data_source, import_csv_monitor))
    end

    def update
      notification_configuration.update!(notification_configuration_params)
      respond_with(notification_configuration, location: edit_data_source_import_csv_monitor_path(data_source, import_csv_monitor))
    end

    def destroy
      notification_configuration.destroy!
      respond_with(notification_configuration, location: edit_data_source_import_csv_monitor_path(data_source, import_csv_monitor))
    end

    private def data_source
      @data_source ||= GrdaWarehouse::DataSource.viewable_by(
        current_user,
        permission: :can_view_projects,
      ).find(params[:data_source_id].to_i)
    end
    helper_method :data_source

    private def import_csv_monitor
      @import_csv_monitor ||= data_source.import_csv_monitors.find(params[:import_csv_monitor_id].to_i)
    end
    helper_method :import_csv_monitor

    def notification_configuration
      @notification_configuration ||= if params[:id].present?
        GrdaWarehouse::NotificationConfiguration.find_safely(params[:id])
      else
        GrdaWarehouse::NotificationConfiguration.new(
          source: import_csv_monitor,
          notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        )
      end
    end
    helper_method :notification_configuration

    private def notification_configuration_params
      params.require(:grda_warehouse_notification_configuration).permit(:user_id, :active)
    end
  end
end
