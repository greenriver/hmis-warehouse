###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ImportsController < ApplicationController
  before_action :require_can_view_imports!
  before_action :set_import, only: [:show, :edit, :update, :destroy, :download]
  helper_method :sort_column, :sort_direction

  # GET /imports
  def index
    @imports = import_scope
    # sort / paginate
    sort = "#{sort_column} #{sort_direction}"
    @imports = @imports.select(:id, :data_source_id, :completed_at, :created_at, :updated_at).
      order(sort).
      page(params[:page].to_i).per(20)
  end

  # GET /imports/new
  def new
    @import = import_source.new
  end

  def show
  end

  def download
    return unless (@upload = @import.upload)

    send_data(@upload.content, type: @upload.content_type, filename: File.basename(@upload.file.to_s)) if @upload.content.present?
  end

  # POST /imports
  def create
    run_import = false
    @import = import_source.new(import_params.merge(percent_complete: 0.0))
    if @import.save
      run_import = true
      flash[:notice] = _('Import queued to start.')
      redirect_to action: :index
    else
      flash[:alert] = _('Import failed to queue.')
      render :new
    end
    Importing::RunImportHudZipJob.perform_later(@import.id) if run_import
  end

  # PATCH/PUT /imports/1
  def update
    if @import.update(import_params)
      redirect_to action: :index
      flash[:notice] = _('Import was successfully updated.')
    else
      render :edit
    end
  end

  # DELETE /imports/1
  def destroy
    @import.destroy
    flash[:notice] = _('Import was successfully removed.')
    redirect_to imports_url
  end

  private

  def import_source
    Import
  end

  def import_scope
    GrdaWarehouse::ImportLog.viewable_by(current_user)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_import
    @import = import_scope.find(params[:id].to_i)
  end

  # Only allow a trusted parameter "white list" through.
  def import_params
    params.require(:import).permit(
      :file,
      :source,
      :import_type,
    )
  end

  def sort_column
    import_source.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
