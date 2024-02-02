###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UploadsController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :edit]

  def index
    attributes = GrdaWarehouse::Upload.column_names - ['import_errors', 'content']
    @uploads = upload_source.with_attached_hmis_zip.select(*attributes).
      where(data_source_id: @data_source.id).
      order(created_at: :desc)
    @pagy, @uploads = pagy(@uploads)
  end

  def new
    @upload = upload_source.new
  end

  def show
  end

  def create
    run_import = false
    # Prevent create if user forgot to include file
    unless upload_params[:hmis_zip]
      @upload = upload_source.new
      flash[:alert] = Translation.translate('You must attach a file in the form.')
      render :new
      return
    end
    @upload = upload_source.create!(
      upload_params.merge(
        percent_complete: 0.0,
        data_source_id: @data_source.id,
        user_id: current_user.id,
        file: 'See S3', # Temporary until we remove the column
      ),
    )
    if @upload.persisted?
      run_import = true
      flash[:notice] = Translation.translate('Upload queued to start.')
      redirect_to action: :index
    else
      flash[:alert] = Translation.translate('Upload failed to queue, did you attach a file?')
      render :new
    end
    return unless run_import

    options = {
      upload_id: @upload.id,
      data_source_id: @upload.data_source_id,
      deidentified: @upload.deidentified,
      project_whitelist: @upload.project_whitelist,
    }
    job_class = Importing::HudZip::HmisAutoMigrateJob
    job = Delayed::Job.enqueue job_class.new(**options), queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    @upload.update(delayed_job_id: job.id)
  end

  private def upload_params
    params.require(:grda_warehouse_upload).
      permit(:deidentified, :project_whitelist, :hmis_zip)
  end

  private def data_source_source
    GrdaWarehouse::DataSource
  end

  private def data_source_scope
    data_source_source.importable.directly_viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:data_source_id].to_i)
  end

  private def set_upload
    @upload = upload_source.find(params[:id].to_i)
  end

  def upload_source
    GrdaWarehouse::Upload
  end
end
