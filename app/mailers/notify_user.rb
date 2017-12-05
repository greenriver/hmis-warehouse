class NotifyUser < ApplicationMailer

  def vispdat_completed vispdat_id
    @vispdat = GrdaWarehouse::Vispdat::Base.where(id: vispdat_id).first
    @user = User.where(id: @vispdat.user_id).first
    users_to_notify = User.where(notify_on_vispdat_completed: true).where.not(id: @user.id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "[Warehouse] A VI-SPDAT was completed.")
    end
  end

  def client_added client_id
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    @user = User.where(id: @client.creator_id).first
    users_to_notify = User.where(notify_on_client_added: true).where.not(id: @user.id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "[Warehouse] A Client was added.")
    end
  end

  def file_uploaded file_id
    @file = GrdaWarehouse::ClientFile.find( file_id )
    @client = @file.client
    users_to_notify = @client.user_clients.includes(:user)
    users_to_notify.each do |user_client|
      mail(to: user_client&.user&.email, subject: "[Warehouse] A file was uploaded.") if user_client.client_notifications?
    end
  end

  def note_added note_id
    @note = GrdaWarehouse::ClientNotes::Base.find( note_id )
    @client = @note.client
    users_to_notify = @client.user_clients.includes(:user)
    users_to_notify.each do |user_client|
      mail(to: user_client&.user&.email, subject: "[Warehouse] A note was added.") if user_client.client_notifications?
    end
  end

end
