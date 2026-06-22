###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DigestMailer < ApplicationMailer
  def digest(user, messages)
    @messages = messages
    return unless user.active?

    mail to: user.email, subject: "#{prefix} #{user.email_schedule} digest"
  end
end
