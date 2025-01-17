###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class NotificationConfigurationsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :data_source
  before_action :import_threshold

  def new
    @form_url = data_source_import_threshold_notification_configurations_path(notification_slug: import_threshold.valid_notification_slug(params[:notification_slug]))
  end

  def edit
    @form_url = data_source_import_threshold_notification_configuration_path(notification_slug: import_threshold.valid_notification_slug(params[:notification_slug]))
  end

  def create
    notification_configuration.update!(notification_configuration_params.merge(notification_slug: import_threshold.valid_notification_slug(params[:notification_slug])))
    respond_with(notification_configuration, location: data_source_import_threshold_path)
  end

  def update
    notification_configuration.update!(notification_configuration_params)
    respond_with(notification_configuration, location: data_source_import_threshold_path)
  end

  def destroy
    notification_configuration.destroy!
    respond_with(notification_configuration, location: data_source_import_threshold_path)
  end

  private def notification_configuration_params
    params.require(:grda_warehouse_notification_configuration).
      permit(:user_id, :active)
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
  helper_method :data_source

  private def import_threshold
    @import_threshold ||= data_source.import_threshold
  end
  helper_method :import_threshold

  def notification_configuration
    @notification_configuration ||= if params[:id].to_i.positive?
      GrdaWarehouse::NotificationConfiguration.find(params[:id].to_i)
    else
      GrdaWarehouse::NotificationConfiguration.new(
        source: import_threshold,
        notification_slug: import_threshold.valid_notification_slug(params[:notification_slug]),
      )
    end
  end
  helper_method :notification_configuration
end
