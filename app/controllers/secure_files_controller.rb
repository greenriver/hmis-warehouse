###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SecureFilesController < ApplicationController
  before_action :require_can_view_some_secure_files!, only: [:show]
  before_action :set_file, only: [:show, :destroy]

  def index
    @secure_file = file_source.new
    @secure_files = file_scope
  end

  def show
    filename = @secure_file.file&.file&.filename&.to_s || 'secure_file'
    send_data(
      @secure_file.content,
      type: @secure_file.content_type,
      filename: File.basename(filename),
    )
  end

  def destroy
    @secure_file.destroy
    respond_with @secure_file, location: secure_files_path
  end

  def create
    # Prevent create if user forgot to include file
    unless file_params[:file]
      @secure_file = file_source.new
      flash[:alert] = _('You must attach a file in the form.')
      render(:index)
      return
    end
    file = file_params[:file]
    @secure_file = file_source.new(
      file_params.merge(
        sender_id: current_user.id,
        content_type: file.content_type,
        content: file.read,
      ),
    )
    if @secure_file.save
      flash[:notice] = _('Upload successful, please let the recipient know the file has been sent.')
      redirect_to action: :index
    else
      flash[:alert] = _('Upload failed, did you attach a file?')
      @secure_files = file_scope
      render :index
    end
  end

  private def file_params
    params.require(:secure_file).
      permit(:file, :name, :recipient_id)
  end

  private def set_file
    @secure_file = file_scope.find(params[:id].to_i)
  end

  def file_scope
    GrdaWarehouse::SecureFile.visible_by?(current_user)
  end

  def file_source
    GrdaWarehouse::SecureFile
  end

  def flash_interpolation_options
    { resource_name: 'File' }
  end
end
