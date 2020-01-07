###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class FileNotificationMailer < DatabaseMailer
  def notify(client_id)
    @client_id = client_id
    @notify = User.active.receives_file_notifications
    @notify.each do |user|
      mail(to: user.email, subject: 'File upload notification')
    end
  end
end
