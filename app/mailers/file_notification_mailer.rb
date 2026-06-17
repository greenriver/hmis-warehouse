###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FileNotificationMailer < DatabaseMailer
  def notify(client_id)
    @client_id = client_id
    @notify = User.active.receives_file_notifications
    @notify.each do |user|
      mail(to: user.email, subject: 'File upload notification')
    end
  end
end
