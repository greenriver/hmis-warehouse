###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::GlobalFeatureFlags < Types::BaseObject
    skip_activity_log

    field :id, ID, null: false # current user ID for apollo caching
    field :coordinated_entry_enabled, Boolean, null: false, description: 'Whether Coordinated Entry is enabled'
    field :bulk_void_enabled, Boolean, null: false, description: 'Whether Bulk Void is enabled'
    field :external_referrals_enabled, Boolean, null: false, description: 'Whether an external referral integration is enabled'
    field :mci_id_enabled, Boolean, null: false, description: 'Whether MCI ID integration is enabled'
    field :esg_funding_report_enabled, Boolean, null: false, description: 'Whether the ESG Funding Report is enabled'

    def id
      current_user.id # ID to use as a cache key for Apollo
    end

    def coordinated_entry_enabled
      Hmis::Ce.configuration.enabled?
    end

    def bulk_void_enabled
      Hmis::Ce.configuration.bulk_void_enabled?
    end

    def external_referrals_enabled
      HmisExternalApis::AcHmis::LinkApi.enabled?
    end

    def mci_id_enabled
      HmisExternalApis::AcHmis::Mci.enabled?
    end

    def esg_funding_report_enabled
      HmisExternalApis::AcHmis::Configuration.esg_funding_report_enabled?
    end
  end
end
