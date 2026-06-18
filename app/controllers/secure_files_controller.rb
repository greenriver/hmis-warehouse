###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SecureFilesController < ApplicationControllerV2
  authorize_with { current_user.can_view_some_secure_files? }
  authorize_with(only: :all_files) { current_user.can_view_all_secure_uploads? }
  before_action :set_file, only: [:show, :destroy]
  before_action :build_secure_file, only: [:index, :sent, :all_files]

  # Received tab (default)
  def index
    @active_tab = :received
    @secure_files = file_scope.received_by(current_user).order(created_at: :desc)
  end

  # Sent tab
  def sent
    @active_tab = :sent
    @secure_files = file_scope.where(sender_id: current_user.id).order(created_at: :desc)
    render(:index)
  end

  # All Files tab (admin-only, gated above)
  def all_files
    @active_tab = :all
    @secure_files = file_scope.order(created_at: :desc)
    render(:index)
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
    success = @secure_file.destroy
    flash[:notice] = Translation.translate("Secure File Removed") if success
    # Return to whichever tab the user removed the file from (falls back to Received).
    redirect_back(fallback_location: secure_files_path)
  end

  def create
    # Prevent create if user forgot to include file
    return render_index_with_alert('You must attach a file in the form.') unless file_params[:file]

    recipients = file_params[:recipients]&.select(&:present?)&.map(&:to_i)
    return render_index_with_alert('Upload failed, did you attach a file and choose a recipient?') if recipients.blank?

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
      return render_index_with_alert('Upload failed, did you attach a file and choose a recipient?')
    end

    # Notify only after the transaction commits, so recipients are never emailed
    # about files that were rolled back.
    recipients.each { |recipient_id| NotifyUser.secure_file_received(recipient_id).deliver_later } if send_notifications

    message = 'Upload successful'
    message += ", please let the #{'recipient'.pluralize(recipients.count)} know the file has been sent." unless send_notifications
    message += ', notifications have been sent' if send_notifications
    flash[:notice] = message
    redirect_to action: :sent
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

  private def build_secure_file
    @secure_file = file_source.new
  end

  # Empty-state message for the active tab, passed to render_paginated_list.
  def secure_files_empty_message
    case @active_tab
    when :sent
      'You have not sent any secure files in the past month.'
    when :all
      'No secure files found.'
    else
      'You have not received any secure files in the past month.'
    end
  end
  helper_method :secure_files_empty_message

  # render the Received tab with an alert; used by create's failure exits
  private def render_index_with_alert(message)
    @secure_file  = file_source.new
    @active_tab   = :received
    @secure_files = file_scope.received_by(current_user).order(created_at: :desc)
    flash.now[:alert] = Translation.translate(message)
    render(:index)
  end

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
