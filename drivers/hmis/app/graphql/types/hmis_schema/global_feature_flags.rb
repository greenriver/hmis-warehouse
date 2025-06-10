###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::GlobalFeatureFlags < Types::BaseObject
    field :coordinated_entry_enabled, Boolean, null: false, description: 'Whether Coordinated Entry is enabled'
    field :external_referrals_enabled, Boolean, null: false, description: 'Whether an external referral integration is enabled'
    field :mci_id_enabled, Boolean, null: false, description: 'Whether MCI ID integration is enabled'

    def coordinated_entry_enabled
      Hmis::Ce.configuration.enabled?
    end

    def external_referrals_enabled
      HmisExternalApis::AcHmis::Mper.enabled?
    end

    def mci_id_enabled
      HmisExternalApis::AcHmis::Mci.enabled?
    end
  end
end
