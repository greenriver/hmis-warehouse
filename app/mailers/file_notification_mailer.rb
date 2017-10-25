class FileNotificationMailer < ApplicationMailer

  def notify tag_ids, client_id
    # @tags = ActsAsTaggableOn::Tag.where(id: tag_ids)
    @client_id = client_id
    @notify = User.receives_file_notifications
    @notify.each do |user|
      mail(to: user.email, subject: "[Warehouse] File upload notification")
    end
  end
end