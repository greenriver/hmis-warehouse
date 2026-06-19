###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TokenMailer < DatabaseMailer
  def note_added(user, token)
    @user = user
    @token = token
    return unless @user.active?

    mail(to: @user.email, subject: 'Client note added')
  end
end
