###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CustomAuthFailure < Devise::FailureApp
  def respond
    if scope == :hmis_user
      # If the request is a JSON POST request, it is probably a GraphQL API request. Return a JSON error.
      # This is the case when the user signs out in another tab or the session becomes invalid
      is_json = request.content_type == 'application/json' || request.format == :json
      return json_error_response if request.post? && is_json

      # If this is a GET request, it is probably the OKTA callback. Redirect back to the front-end.
      # This is the case when OKTA authentication succeeds but the devise account is locked or inactive
      return redirect_to_hmis if ENV['HMIS_OKTA_CLIENT_ID'].present?
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
