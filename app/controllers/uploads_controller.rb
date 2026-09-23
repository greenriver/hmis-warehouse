###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UploadsController < ApplicationController
  before_action :require_can_upload_hud_zips!
  before_action :set_data_source
  before_action :set_upload, only: [:show, :edit, :confirm]

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
    unless @data_source.importable?
      flash[:alert] = Translation.translate('Imports are disabled for this data source.')
      redirect_to data_source_uploads_path(@data_source)
      return
    end

    # Confirm the destination before touching the file
    unless typed_short_name_matches?
      @upload = upload_source.new
      flash.now[:alert] = Translation.translate('The data source name you typed does not match this data source.')
      render :new
      return
    end

    # Prevent create if user forgot to include file
    unless upload_params[:hmis_zip]
      @upload = upload_source.new
      flash.now[:alert] = Translation.translate('You must attach a file in the form.')
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
    unless @upload.persisted?
      flash.now[:alert] = Translation.translate('Upload failed to queue, did you attach a file?')
      render :new
      return
    end

    @export_source = HmisCsvImporter::UploadValidityCheck.for_upload(@upload)
    if @export_source.hard_reject?
      @upload.destroy
      @upload = upload_source.new
      flash.now[:alert] = @export_source.error_message
      render :new
      return
    end

    if @export_source.source_id_matches?(@data_source.source_id)
      enqueue_import(@upload, source_id_override: false)
      flash[:notice] = Translation.translate('Upload queued to start.')
      redirect_to action: :index
      return
    end

    # Blank, mismatched, or unverifiable SourceID: hold the upload for acknowledgment
    @dry_run = dry_run_param
    render :confirm
  end

  # Acknowledge a SourceID the upload validity check could not match, and queue the import.
  def confirm
    # A confirmed upload has already been queued; re-posting would enqueue a
    # second import of the same file, which the job's advisory lock serializes
    # but does not discard.
    unless @upload.awaiting_confirmation?
      flash[:alert] = Translation.translate('That upload is no longer waiting for confirmation.')
      redirect_to action: :index
      return
    end

    unless params[:acknowledge] == '1'
      @export_source = HmisCsvImporter::UploadValidityCheck.for_upload(@upload)
      @dry_run = dry_run_param
      flash.now[:alert] = Translation.translate('You must acknowledge the mismatch to continue.')
      render :confirm
      return
    end

    # Re-read the file rather than trusting values posted back from the form
    @export_source = HmisCsvImporter::UploadValidityCheck.for_upload(@upload)
    if @export_source.hard_reject?
      @upload.destroy
      @upload = upload_source.new
      flash.now[:alert] = @export_source.error_message
      render :new
      return
    end

    @upload.update!(
      export_source_check: {
        'typed_short_name' => @data_source.short_name,
        'data_source_source_id' => @data_source.source_id,
        'file_source_id' => @export_source.source_id,
        'file_source_name' => @export_source.source_name,
        'check_error' => @export_source.error&.to_s,
        'acknowledged_at' => Time.current,
        'acknowledged_by_user_id' => current_user.id,
      },
    )

    enqueue_import(@upload, source_id_override: @upload.source_id_overridden?)
    flash[:notice] = Translation.translate('Upload queued to start.')
    redirect_to action: :index
  end

  private def enqueue_import(upload, source_id_override:)
    job = Importing::HudZip::HmisAutoMigrateJob.perform_later(
      upload_id: upload.id,
      data_source_id: upload.data_source_id,
      deidentified: upload.deidentified,
      allowed_projects: upload.project_whitelist,
      stop_version: stop_version,
      dry_run: dry_run_param,
      source_id_override: source_id_override,
    )
    upload.update(delayed_job_id: job.provider_job_id)
  end

  private def typed_short_name_matches?
    typed = params.dig(:grda_warehouse_upload, :short_name_confirmation).to_s.strip
    typed.casecmp(@data_source.short_name.to_s.strip).zero?
  end

  private def stop_version
    Importers::HmisAutoMigrate.current_stop_version
  end

  # Not a column on uploads, so it rides the confirm form as a hidden field
  private def dry_run_param
    params.dig(:grda_warehouse_upload, :dry_run) == '1'
  end

  private def upload_params
    params.require(:grda_warehouse_upload).
      permit(:deidentified, :project_whitelist, :hmis_zip)
  end

  private def data_source_source
    GrdaWarehouse::DataSource
  end

  private def data_source_scope
    data_source_source.directly_viewable_by(current_user)
  end

  private def set_data_source
    @data_source = data_source_scope.find(params[:data_source_id].to_i)
  end

  private def set_upload
    @upload = upload_source.where(data_source_id: @data_source.id).find(params[:id].to_i)
  end

  def upload_source
    GrdaWarehouse::Upload
  end
end
