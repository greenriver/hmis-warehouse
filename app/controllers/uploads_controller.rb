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

    # Prevent create if user forgot to include file
    file = upload_params[:hmis_zip]
    unless file
      @upload = upload_source.new
      flash.now[:alert] = Translation.translate('You must attach a file in the form.')
      render :new
      return
    end

    # Checked while the archive is still the request's own tempfile. Storing it first
    # and reading it back would pull the whole thing down again to read one member.
    @export_source = HmisCsvImporter::UploadValidityCheck.for_uploaded_file(file)
    if @export_source.hard_reject?
      @upload = upload_source.new
      flash.now[:alert] = @export_source.error_message
      render :new
      return
    end

    @upload = upload_source.create!(
      upload_params.merge(
        percent_complete: 0.0,
        data_source_id: @data_source.id,
        user_id: current_user.id,
        file: 'See S3', # Temporary until we remove the column
        export_source_check: export_source_check_attributes,
      ),
    )

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

  # Name the destination data source to accept a SourceID the upload validity check
  # could not match, and queue the import.
  def confirm
    # A confirmed upload has already been queued; re-posting would enqueue a
    # second import of the same file, which the job's advisory lock serializes
    # but does not discard.
    unless @upload.awaiting_confirmation?
      flash[:alert] = Translation.translate('That upload is no longer waiting for confirmation.')
      redirect_to action: :index
      return
    end

    # The stored row records what the check read from the file at upload time, so the
    # form cannot post back something different and the archive is not read again.
    @export_source = HmisCsvImporter::UploadValidityCheck::Result.from_audit_h(@upload.export_source_check)

    # The SourceID did not vouch for the destination, so the user names it instead
    unless typed_short_name_matches?
      @dry_run = dry_run_param
      flash.now[:alert] = Translation.translate('The data source name you typed does not match this data source.')
      render :confirm
      return
    end

    @upload.update!(
      export_source_check: @upload.export_source_check.merge(
        'typed_short_name' => typed_short_name,
        'acknowledged_at' => Time.current,
        'acknowledged_by_user_id' => current_user.id,
      ),
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

  # The audit row read by the confirmation screen and Upload#source_id_overridden?.
  # #confirm adds the typed name and the acknowledgment to it.
  private def export_source_check_attributes
    @export_source.to_audit_h.merge('data_source_source_id' => @data_source.source_id)
  end

  # A data source with no short name would otherwise be confirmed by an empty box
  private def typed_short_name_matches?
    typed_short_name.present? && typed_short_name.casecmp(@data_source.short_name.to_s.strip).zero?
  end

  private def typed_short_name
    params.dig(:grda_warehouse_upload, :short_name_confirmation).to_s.strip
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
