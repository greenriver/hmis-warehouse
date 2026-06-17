###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

OAuth2.configure do |config|
  # https://gitlab.com/oauth-xx/oauth2#global-configuration
  config.silence_extra_tokens_warning = true # default: false
end
