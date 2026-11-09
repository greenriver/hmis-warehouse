###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ImportThresholdsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :require_can_edit_data_sources_or_warehouse_alerts!, only: [:update]
  before_action :data_source
  before_action :import_threshold

  def show
    @import_csv_monitors = data_source.import_csv_monitors.order(:csv_file_name)
    monitor_csv_file_names = @import_csv_monitors.map(&:csv_file_name)
    @metric_defs_by_subtype = GrdaWarehouse::Monitoring::MetricDefinition.
      where(entity_type: 'GrdaWarehouse::DataSource', subtype: monitor_csv_file_names).
      index_by(&:subtype)
  end

  def update
    import_threshold.update!(import_threshold_params)
    respond_with(import_threshold, location: data_source_import_threshold_path)
  end

  private def import_threshold_params
    params.require(:grda_warehouse_import_threshold).
      permit(*GrdaWarehouse::ImportThreshold.known_params)
  end

  private def require_can_edit_data_sources_or_warehouse_alerts!
    not_authorized! unless can_edit_data_sources? || can_edit_warehouse_alerts?
  end

  # Anyone who can view the data source may see its thresholds (notification emails link here).
  # Changing them requires edit rights on this data source, or the warehouse-wide alerts
  # permission (the admin alerts page links here for every data source).
  private def data_source_scope
    viewable = GrdaWarehouse::DataSource.viewable_by(current_user, permission: :can_view_projects)
    return viewable unless action_name == 'update'
    return viewable if can_edit_warehouse_alerts?

    GrdaWarehouse::DataSource.editable_by(current_user)
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
