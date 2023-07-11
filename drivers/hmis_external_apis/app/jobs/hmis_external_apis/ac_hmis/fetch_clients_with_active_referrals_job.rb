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

      Hmis::Hud::CustomDataElement.import(
        Hmis::Hud::Client.
          where(id: client_ids).
          map do |client|
            cde = client.custom_data_elements.where(data_element_definition: cded).first_or_create!(data_source: data_source, user: system_user, value_boolean: true)
            cde.value_boolean = true
            cde
          end,
        on_duplicate_key_update: { conflict_target: [:id], columns: [:value_boolean] },
      )

      Hmis::Hud::CustomDataElement.
        where(owner_type: 'Hmis::Hud::Client', data_element_definition: cded).
        where.not(owner_id: client_ids).
        update_all(value_boolean: false)
    end
  end
end
