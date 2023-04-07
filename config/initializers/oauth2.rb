###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

OAuth2.configure do |config|
  # https://gitlab.com/oauth-xx/oauth2#global-configuration
  config.silence_extra_tokens_warning = true # default: false
end
