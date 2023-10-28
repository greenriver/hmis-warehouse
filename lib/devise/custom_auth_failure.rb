###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CustomAuthFailure < Devise::FailureApp
  def respond
    if scope == :hmis_user
      return redirect_to_hmis if ENV['HMIS_OKTA_CLIENT_ID'].present?

      return json_error_response if request.format == :json
    end
    super
  end

  def redirect_to_hmis
    self.status = 302
    auth_error =  warden_message || 'other'
    headers['Location'] = "/?authError=#{auth_error}"
  end

  def json_error_response
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { error: { type: warden_message || :unauthenticated, message: i18n_message } }.to_json
  end
end
