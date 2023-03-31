###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class OauthIdentity < ApplicationRecord
  belongs_to :user

  # @param user [User, Hmis::User]
  def self.for_user(user)
    where(user_id: user.id)
  end

  def issuer
    raw_info.dig('id_info', 'iss')
  end

  def id_token
    raw_info['id_token']
  end

  # https://developer.okta.com/docs/reference/api/oidc/#logout
  # @param post_logout_redirect_uri [String]
  # @param state [String]
  def idp_signout_url(post_logout_redirect_uri: nil, state: 'provider-was-okta')
    if issuer.present? && id_token.present?
      "#{issuer}/v1/logout?" + {
        id_token_hint: id_token,
        post_logout_redirect_uri: post_logout_redirect_uri,
        state: state,
      }.compact.to_param
    else
      post_logout_redirect_uri
    end
  end
end
