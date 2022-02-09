###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TokenMailer < DatabaseMailer
  def note_added(user, token)
    @user = user
    @token = token
    return unless @user.active?

    mail(to: @user.email, subject: 'Client note added')
  end
end
