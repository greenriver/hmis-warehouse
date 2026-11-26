###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if SandboxEmailInterceptor.enabled?
end
