###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class FetchClientsWithActiveReferralsJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    include HmisExternalApis::AcHmis::ReferralJobMixin
    include NotifierConfig

    def perform
      return unless HmisExternalApis::AcHmis::LinkApi.enabled?

      setup_notifier('Fetch clients with active referrals in LINK')

      # Fetch MCI IDs for clients with active referrals in LINK
      begin
        mci_ids = link.active_referral_mci_ids.parsed_body
      rescue StandardError
        # LinkApi class already logs the error details to Sentry
        debug_msg('Stopping, LINK API call failed')
        return
      end
      debug_msg "Fetched #{mci_ids.uniq.size} MCI IDs with active referrals from LINK"

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
        repeats: false, # client can only have 1 value
        data_source: data_source,
        user: system_user,
      )

      # Update clients who already had a CDE value (and are present in this batch)
      cdes_to_update = Hmis::Hud::CustomDataElement.where(owner_type: 'Hmis::Hud::Client', owner_id: client_ids, data_element_definition: cded)
      num_updated_to_true = cdes_to_update.update_all(value_boolean: true, user_id: system_user.user_id)
      debug_msg "Updated #{num_updated_to_true} existing records for clients with active referrals"

      # Create new records for clients that didn't have a CDE value
      cde_attributes_to_create = (client_ids - cdes_to_update.pluck(:owner_id)).map do |client_id|
        {
          owner_type: 'Hmis::Hud::Client',
          owner_id: client_id,
          data_element_definition_id: cded.id,
          value_boolean: true,
          data_source_id: data_source.id,
          UserID: system_user.user_id,
        }
      end
      Hmis::Hud::CustomDataElement.import(cde_attributes_to_create)
      debug_msg "Created #{cde_attributes_to_create.size} new records"

      # Update clients who already had a CDE value (and are NOT present in this batch)
      num_updated_to_false = Hmis::Hud::CustomDataElement.
        where(owner_type: 'Hmis::Hud::Client', data_element_definition: cded).
        where.not(owner_id: client_ids).
        update_all(value_boolean: false)
      debug_msg "Updated #{num_updated_to_false} existing records for clients without active referrals"
    end

    def debug_msg(str)
      @notifier.ping(str)
    end
  end
end
