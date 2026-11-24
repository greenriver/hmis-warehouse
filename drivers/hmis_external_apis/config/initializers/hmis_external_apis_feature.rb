###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

if ENV['ENABLE_HMIS_API'] == 'true'
  # The inbound LINK Referral API was removed, so its API keys no longer authorize anything.
  Rails.application.config.queued_tasks[:hmis_external_apis_remove_referrals_api_keys] = -> do
    HmisExternalApis::InboundApiConfiguration.joins(:internal_system).where(internal_systems: { name: 'Referrals' }).destroy_all
  end
end
