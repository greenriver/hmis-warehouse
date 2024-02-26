###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImportOverridesController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source

  def index
    @overrides = import_override_scope.sorted
  end

  def create
    @override = import_override_source.create!(permitted_params.merge(data_source_id: @data_source.id))
    respond_with(@override, location: hmis_csv_importer_data_source_import_overrides_path(@data_source))
  end

  def destroy
  end

  private def set_data_source
    @data_source = GrdaWarehouse::DataSource.find(params[:data_source_id])
    @data_source = ActiveRecord::RecordNotFound unless @data_source.directly_viewable_by?(current_user, permission: :can_upload_hud_zips)
  end

  private def import_override_source
    HmisCsvImporter::ImportOverride
  end

  private def import_override_scope
    import_override_source.where(data_source: @data_source)
  end

  private def permitted_params
    params.require(:override).
      permit(import_override_source.known_columns)
  end
end
