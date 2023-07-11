###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# An HMIS User indicates that there is a vacancy in a program.
module HmisExternalApis::AcHmis
  class FetchClientsWithActiveReferralsJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    def perform
      mci_ids = link.active_referral_mci_ids.parsed_body
      client_ids = HmisExternalApis::ExternalId.where(
        namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
        value: mci_ids.map(&:to_s),
        source_type: 'Hmis::Hud::Client',
      ).pluck(:source_id)

      cded = Hmis::Hud::CustomDataElementDefinition.where(key: :has_active_referrals_in_link).first_or_create!(
        owner_type: 'Hmis::Hud::Client',
        field_type: :boolean,
        key: :has_active_referrals_in_link,
        label: 'Has Active Referrals in LINK',
        repeats: false,   # client can only have 1 value
        data_source: data_source,
        user: system_user,
      )

      cdes_to_update = Hmis::Hud::CustomDataElement.where(owner_type: 'Hmis::Hud::Client', owner_id: client_ids, data_element_definition: cded)
      cdes_to_update.update_all(value_boolean: true, user_id: system_user.user_id)

      cde_attributes_to_create = (client_ids - cdes_to_update.pluck(:owner_id)).map do |client_id|
        {
          owner_type: 'Hmis::Hud::Client',
          owner_id: client_id,
          data_element_definition_id: cded.id,
          value_boolean: true,
          data_source_id: data_source.id,
          UserID: system_user.id,
        }
      end
      Hmis::Hud::CustomDataElement.import(cde_attributes_to_create)

      Hmis::Hud::CustomDataElement.
        where(owner_type: 'Hmis::Hud::Client', data_element_definition: cded).
        where.not(owner_id: client_ids).
        update_all(value_boolean: false)
    end
  end
end
