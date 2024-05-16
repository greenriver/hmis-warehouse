###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CustomAuthFailure < Devise::FailureApp
  # request is a ActionDispatch::Request
  def respond
    if scope == :hmis_user
      # This is probably an OKTA callback. Redirect back to the front-end.
      # This is the case when OKTA authentication succeeds but the devise account is locked or inactive
      return redirect_to_hmis if request.get? && request.original_fullpath =~ /\A\/hmis\/users\/auth\/okta\/callback/

      # This is probably a GraphQL API or current user/settings request. Return a JSON error for SPA to handle.
      # This is the case when the user signs out in another tab or the session becomes invalid for another reason
      return json_error_response if request.media_type == 'application/json' || request.format == :json
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
