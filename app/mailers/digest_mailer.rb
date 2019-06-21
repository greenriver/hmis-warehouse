###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class DigestMailer < ApplicationMailer

  def digest user, messages
    @messages = messages
    mail to: user.email, subject: "#{prefix} #{user.email_schedule} digest"
  end

end
