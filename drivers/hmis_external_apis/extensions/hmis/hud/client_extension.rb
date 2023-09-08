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
          has_one :ac_hmis_mci_unique_id,
                  -> { where(namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE) },
                  class_name: 'HmisExternalApis::ExternalId',
                  as: :source

          # prepend is needed to destroy referrals before household_members are destroyed
          before_destroy :destroy_hoh_external_referrals, prepend: true

          # On Client form submission, validate that client has MCI ID (if required)
          #
          # NOTE: important that this only happens when _client_ form is submitted, not other form types.
          # When submitting a Client Enrollment form, the Enrollment handles validation of MCI presence.
          validate :validate_mci_id_exists, on: :client_form

          # remove referrals where this client is the the HOH
          def destroy_hoh_external_referrals
            HmisExternalApis::AcHmis::Referral
              .where(id: external_referral_household_members.heads_of_households.select(:referral_id))
              .each(&:destroy!)
          end

          # Used by ClientSearch concern
          def self.search_by_external_id(where, text)
            eid_t = HmisExternalApis::ExternalId.arel_table
            matches_external_value = eid_t[:source_type].eq(sti_name).and(eid_t[:value].eq(text))
            client_ids = HmisExternalApis::ExternalId.where(matches_external_value).pluck(:source_id)
            return where unless client_ids.any?

            where.or(arel_table[:id].in(client_ids))
          end

          private def validate_mci_id_exists
            return unless HmisExternalApis::AcHmis::Mci.enabled?
            # Valid if client has an MCI ID, or is going to create one
            return if ac_hmis_mci_ids.exists? || send(:create_mci_id)

            # If brand new Client record (NOT in context of an Enrollment), then MCI clearance is required
            clearance_required = true if new_record?

            if persisted?
              # MCI clearance is required unless this client is ONLY enrolled at SO/NBN program(s)
              ptypes = HmisExternalApis::AcHmis::Mci::PROJECT_TYPES_NOT_REQUIRING_CLEARANCE
              so_nbn_enrollment_count = enrollments.with_project_type(ptypes).size
              only_so_nbn_enrollments = so_nbn_enrollment_count.positive? && so_nbn_enrollment_count == enrollments.size
              clearance_required = !only_so_nbn_enrollments
            end

            return unless clearance_required

            # Add in some custom options (handled by HmisErrors::Error) so it shows up on the correct fields
            full_msg = HmisExternalApis::AcHmis::Mci::MCI_REQUIRED_MSG
            errors.add :id, :required, attribute_override: :mci_id, readable_attribute: 'MCI ID', full_message: full_msg
          end
        end
      end
    end
  end
end
