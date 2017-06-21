class UploadsController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :edit]

  def index
    @uploads = Upload.where(data_source_id: @data_source.id)
      .page(params[:page].to_i).per(20)
  end

  def new
    @upload = Upload.new
  end

  def show

  end

  def create
    run_import = false
    @upload = Upload.new(upload_params.merge({
      percent_complete: 0.0, 
      data_source_id: @data_source.id, 
      user_id: current_user.id
      }))
    if @upload.save
      run_import = true
      flash[:notice] = "#{Upload.model_name.human} queued to start."
      redirect_to action: :index
    else
      flash[:alert] = "#{Upload.model_name.human} failed to queue."
      render :new
    end
    Importing::RunImportHudZipJob.perform_later(upload: @upload) if run_import
  end

  private def upload_params
    params.require(:upload).
      permit(:file)
  end

  private def data_source_source
    GrdaWarehouse::DataSource.viewable_by current_user
  end

  private def data_source_scope
    data_source_source.importable
  end

  private def set_data_source
    @data_source = data_source_source.find(params[:data_source_id].to_i)
  end

  private def set_upload
    @upload = Upload.find(params[:id].to_i)
  end
end