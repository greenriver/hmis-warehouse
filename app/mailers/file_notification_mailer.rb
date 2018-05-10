class FileNotificationMailer < DatabaseMailer

  def notify client_id
    @client_id = client_id
    @notify = User.receives_file_notifications
    @notify.each do |user|
      mail(to: user.email, subject: "File upload notification")
    end
  end
end