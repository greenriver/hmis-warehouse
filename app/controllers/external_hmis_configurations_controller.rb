###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ExternalHmisConfigurationsController < ApplicationController
  include AjaxModalRails::Controller
  before_action :require_can_edit_data_sources!
  before_action :require_can_view_imports_projects_or_organizations!, only: [:show]
  before_action :data_source
  before_action :external_hmis_configuration

  def show
  end

  def update
    external_hmis_configuration.update!(external_hmis_configuration_params)
    respond_with(external_hmis_configuration, location: data_source_external_hmis_configuration_path)
  end

  private def external_hmis_configuration_params
    params.require(:grda_warehouse_external_hmis_configuration).
      permit(*GrdaWarehouse::ExternalHmisConfiguration.known_params)
  end

  private def data_source_scope
    GrdaWarehouse::DataSource.viewable_by(current_user, permission: :can_edit_data_sources)
  end

  private def data_source
    @data_source ||= data_source_scope.find_safely(params[:data_source_id])
  end
  helper_method :data_source

  # Ensure we have a persisted configuration object (there should never be more than one per data source)
  private def external_hmis_configuration
    @external_hmis_configuration ||= data_source.external_hmis_configuration || GrdaWarehouse::ExternalHmisConfiguration.create!(data_source_id: data_source.id)
  end
  helper_method :external_hmis_configuration
end
