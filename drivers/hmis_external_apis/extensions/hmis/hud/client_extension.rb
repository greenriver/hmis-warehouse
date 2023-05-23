###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module ClientExtension
        extend ActiveSupport::Concern
        include ExternallyIdentifiedMixin

        included do
          has_many :external_ids, class_name: 'HmisExternalApis::ExternalId', as: :source
          has_many :external_referral_household_members, class_name: 'HmisExternalApis::AcHmis::ReferralHouseholdMember', dependent: :destroy, inverse_of: :client
          has_one :ac_hmis_mci_id,
                  -> { where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID) },
                  class_name: 'HmisExternalApis::ExternalId',
                  as: :source

          # Used by ClientSearch concern
          def self.client_ids_with_external_id(value)
            eid_t = HmisExternalApis::ExternalId.arel_table
            HmisExternalApis::ExternalId.where(
              eid_t[:source_type].eq(sti_name).and(eid_t[:value].eq(value)),
            ).pluck(:source_id)
          end
        end
      end
    end
  end
end
