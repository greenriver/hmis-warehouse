###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.after_initialize do
  Idp::JwtHelper.assert_boot_config! if AuthMethod.jwt?
end
