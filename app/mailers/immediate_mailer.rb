###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ImmediateMailer < ApplicationMailer
  def immediate(message, to)
    @message = message
    mail from: message.from, to: to, subject: "#{prefix} #{@message.subject}"
  end
end
