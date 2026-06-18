###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SecureFilesController < ApplicationControllerV2
  authorize_with { current_user.can_view_some_secure_files? }
  before_action :set_file, only: [:show, :destroy]

  def index
    @secure_file = file_source.new
  end

  def show
    secure_file = @secure_file.secure_file
    send_data(
      secure_file.download,
      type: secure_file.content_type,
      filename: secure_file.filename.to_s,
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
      flash.now[:alert] = Translation.translate('You must attach a file in the form.')
      render(:index)
      return
    end

    recipients = file_params[:recipients]&.select(&:present?)&.map(&:to_i)
    if recipients.blank?
      @secure_file = file_source.new
      flash.now[:alert] = Translation.translate('Upload failed, did you attach a file and choose a recipient?')
      render(:index)
      return
    end

    send_notifications = file_params[:send_notifications] == '1'
    begin
      # All recipients succeed or none do: a mid-loop failure must not leave some
      # files created (and notified) while we report total failure to the user.
      file_source.transaction do
        recipients.each do |recipient_id|
          @secure_file = file_source.create!(
            sender_id: current_user.id,
            recipient_id: recipient_id,
            name: file_params[:name],
          )
          @secure_file.secure_file.attach(file_params[:file])
        end
      end
    rescue ActiveRecord::RecordInvalid, ActiveStorage::IntegrityError
      flash.now[:alert] = Translation.translate('Upload failed, did you attach a file and choose a recipient?')
      render :index
      return
    end

    # Notify only after the transaction commits, so recipients are never emailed
    # about files that were rolled back.
    recipients.each { |recipient_id| NotifyUser.secure_file_received(recipient_id).deliver_later } if send_notifications

    message = 'Upload successful'
    message += ", please let the #{'recipient'.pluralize(recipients.count)} know the file has been sent." unless send_notifications
    message += ', notifications have been sent' if send_notifications
    flash[:notice] = message
    redirect_to action: :index
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

  def received_secure_files
    file_scope.received_by(current_user).order(created_at: :desc)
  end
  helper_method :received_secure_files

  def sent_secure_files
    file_scope.where(sender_id: current_user.id).order(created_at: :desc)
  end
  helper_method :sent_secure_files

  def file_scope
    GrdaWarehouse::SecureFile.viewable_by(current_user)
  end

  def file_source
    GrdaWarehouse::SecureFile
  end

  def flash_interpolation_options
    { resource_name: 'File' }
  end
end
