class UploadsController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :edit]

  def index
    attributes = GrdaWarehouse::Upload.column_names - ['import_errors', 'content']
    @uploads = upload_source.select(*attributes).
      where(data_source_id: @data_source.id)
      .page(params[:page].to_i).per(20).order(created_at: :desc)
  end

  def new
    @upload = upload_source.new
  end

  def show

  end

  def create
    run_import = false
    # Prevent create if user forgot to include file
    if !upload_params[:file]
      flash[:alert] = _("You must attach a file in the form.")
      redirect_to action: :new
      return
    end
    file = upload_params[:file]
    @upload = upload_source.new(upload_params.merge({
      percent_complete: 0.0, 
      data_source_id: @data_source.id, 
      user_id: current_user.id,
      content_type: file.content_type,
      content: file.read,
      }))
    if @upload.save
      run_import = true
      flash[:notice] = _("Upload queued to start.")
      redirect_to action: :index
    else
      flash[:alert] = _("Upload failed to queue.")
      render :new
    end
    if run_import
      case params[:grda_warehouse_upload][:import_type]
      when 'hmis_51'
        job = Delayed::Job.enqueue Importing::HudZip::FiveOneJob.new(upload_id: @upload.id, data_source_id: @upload.data_source_id), queue: :default_priority
      when 'hmis_611'
        job = Delayed::Job.enqueue Importing::HudZip::SixOneOneJob.new(upload_id: @upload.id, data_source_id: @upload.data_source_id), queue: :default_priority
      end
      @upload.update(delayed_job_id: job.id)
    end

  end

  private def upload_params
    params.require(:grda_warehouse_upload).
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
    @upload = upload_source.find(params[:id].to_i)
  end

  def upload_source 
    GrdaWarehouse::Upload
  end
end
