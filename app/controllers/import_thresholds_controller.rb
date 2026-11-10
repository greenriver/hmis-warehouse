###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ImportThresholdsController < ApplicationController
  include AjaxModalRails::Controller
  include ImportAlertsAuthorization
  # `show` is intentionally open to read-only viewers: import and CSV monitor alert emails link
  # here, and any active user can be a recipient. Don't gate it on edit rights; the view hides
  # the edit controls with `can_edit_import_alerts?` instead.
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :data_source
  before_action :require_can_edit_import_alerts!, only: [:update]
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
