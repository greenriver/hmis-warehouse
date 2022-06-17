###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CustomAuthFailure < Devise::FailureApp
  def respond
    if warden_options[:scope] == :hmis_api_user && request.format == :json
      json_error_response
    else
      super
    end
  end

  def json_error_response
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { error: { type: 'authentication_failed', message: i18n_message } }.to_json
  end
end
