###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SecureFilesController < ApplicationController
  before_action :require_can_view_some_secure_files!, only: [:show, :destroy, :create]
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
    if recipients.blank?
      @secure_file = file_source.new
      flash[:alert] = Translation.translate('Upload failed, did you attach a file and choose a recipient?')
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
      flash[:alert] = Translation.translate('Upload failed, did you attach a file and choose a recipient?')
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
    # viewable_by already covers recipients, admins, and senders who still hold
    # the role, so the same scope gates both downloading and removal. Out-of-scope
    # ids fall out of the scoped .find, which Rails renders as a 404.
    @secure_file = file_scope.find(params[:id].to_i)
  end

  def received_files
    # The "Received" list shows files sent to you — never files you sent, and not
    # every file in the system even for admins ("Received" means you're the
    # recipient). A permission-gated subset of viewable_by; see
    # SecureFile.received_by.
    #
    # Layered on file_scope (viewable_by) rather than the bare model so the
    # visibility gate is always the outer bound: redundant today since received_by
    # is already a subset, but it guarantees the list can never escape the
    # visibility scope even if received_by later drifts.
    file_scope.received_by(current_user).order(created_at: :desc).diet_select
  end
  helper_method :received_files

  def sent_secure_files
    # Narrow file_scope (viewable_by) to the files this user sent, rather than
    # querying the model directly, so the Sent list can never escape the
    # visibility gate: a user who has lost the role sees nothing here either.
    file_scope.where(sender_id: current_user.id).order(created_at: :desc).diet_select
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
