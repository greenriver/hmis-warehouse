###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SecureFilesController < ApplicationController
  before_action :require_can_view_some_secure_files!, only: [:show]
  before_action :set_file, only: [:show, :destroy]

  def index
    @secure_file = file_source.new
  end

  def show
    secure_file = @secure_file.secure_file
    # Use ActiveStorage version if we have it
    if secure_file.present?
      send_data(
        secure_file.download,
        type: secure_file.content_type,
        filename: secure_file.filename.to_s,
      )
    else
      filename = 'secure_file'
      send_data(
        @secure_file.content,
        type: @secure_file.content_type,
        filename: File.basename(filename),
      )
    end
  end

  def destroy
    @secure_file.destroy
    respond_with @secure_file, location: secure_files_path
  end

  def create
    # Prevent create if user forgot to include file
    unless file_params[:file]
      @secure_file = file_source.new
      flash[:alert] = Translation.translate('You must attach a file in the form.')
      render(:index)
      return
    end

    recipients = file_params[:recipients]&.select(&:present?)&.map(&:to_i)
    send_notifications = file_params[:send_notifications] == '1'
    begin
      @secure_file = file_source.new
      recipients.each do |recipient_id|
        @secure_file = file_source.create!(
          sender_id: current_user.id,
          recipient_id: recipient_id,
          name: file_params[:name],
        )
        @secure_file.secure_file.attach(file_params[:file])
        NotifyUser.secure_file_received(recipient_id).deliver_later if send_notifications
      end
      message = 'Upload successful'
      message += ", please let the #{'recipient'.pluralize(recipients.count)} know the file has been sent." unless send_notifications
      message += ', notifications have been sent' if send_notifications
      flash[:notice] = message
      redirect_to action: :index
    rescue StandardError
      flash[:alert] = Translation.translate('Upload failed, did you attach a file and choose a recipient?')
      render :index
    end
  end

  private def file_params
    params.require(:secure_file).
      permit(
        :file,
        :name,
        :send_notifications,
        recipients: [],
      )
  end

  private def set_file
    @secure_file = file_scope.find(params[:id].to_i)
  end

  def secure_files
    file_scope.order(created_at: :desc).diet_select
  end
  helper_method :secure_files

  def sent_secure_files
    GrdaWarehouse::SecureFile.where(sender_id: current_user.id).order(created_at: :desc).diet_select
  end
  helper_method :sent_secure_files

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
