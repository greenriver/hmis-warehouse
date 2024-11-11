###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImportOverridesController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source

  def index
    available_files = HmisCsvImporter::ImportOverride.available_files_for(@data_source.id)
    @selected_filename = available_files.detect { |f| f == params[:filename] } || available_files.first
    @overrides = import_override_scope.sorted.where(file_name: @selected_filename)
    @pagy, @overrides = pagy(@overrides, items: 25)
  end

  def create
    @override = import_override_source.create(permitted_params.merge(data_source_id: @data_source.id))
    flash[:alert] = @override.errors.full_messages.join(', ') unless @override.valid?
    respond_with(@override, location: hmis_csv_importer_data_source_import_overrides_path(@data_source))
  end

  def destroy
    @override = import_override_source.find(params[:id].to_i)
    @override.destroy
    respond_with(@override, location: hmis_csv_importer_data_source_import_overrides_path(@data_source))
  end

  def apply
    @override = import_override_source.find(params[:id].to_i)
    number_rows_affected = @override.apply_to_warehouse
    flash[:alert] = "#{@override.describe_apply} (#{number_rows_affected} records affected)"
    redirect_to hmis_csv_importer_data_source_import_overrides_path(@data_source)
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
