###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CustomAuthFailure < Devise::FailureApp
  def respond
    if scope == :hmis_user && request.format == :json
      json_error_response
    else
      super
    end
  end

  def json_error_response
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { error: { type: warden_message || :unauthenticated, message: i18n_message } }.to_json
  end
end
