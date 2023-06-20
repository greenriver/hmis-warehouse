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
          has_many :ac_hmis_mci_ids,
                  -> { where(namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID) },
                  class_name: 'HmisExternalApis::ExternalId',
                  as: :source

          # Used by ClientSearch concern
          def self.search_by_external_id(where, text)
            eid_t = HmisExternalApis::ExternalId.arel_table
            matches_external_value = eid_t[:source_type].eq(sti_name).and(eid_t[:value].eq(text))
            client_ids = HmisExternalApis::ExternalId.where(matches_external_value).pluck(:source_id)
            return where unless client_ids.any?

            where.or(arel_table[:id].in(client_ids))
          end
        end
      end
    end
  end
end
