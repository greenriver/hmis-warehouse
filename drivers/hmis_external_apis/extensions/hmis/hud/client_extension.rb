###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module ClientExtension
        extend ActiveSupport::Concern
        include HmisExternalApis::ExternallyIdentifiedMixin

        included do
          has_many :external_ids, class_name: 'HmisExternalApis::ExternalId', as: :source, dependent: :destroy
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

          # Validate First/Last is required, regardless of project
          validate :validate_first_last, on: [:client_form, :new_client_enrollment_form]
          # Validate DOB/DQ fields (required if clearance is required)
          # This is called from enrollment_extension validator, when the Client & Enrollment are being created at the same time
          validate :validate_required_fields_for_clearance, on: :enrollment_requiring_mci

          # On Client form submission, validate that client has MCI ID (if required)
          validate :validate_mci_id_exists, on: :client_form

          # remove referrals where this client is the the HOH
          def destroy_hoh_external_referrals
            HmisExternalApis::AcHmis::Referral.
              where(id: external_referral_household_members.heads_of_households.select(:referral_id)).
              each(&:destroy!)
          end

          # Used by ClientSearch concern
          def self.search_by_external_id(where, text)
            eid_t = HmisExternalApis::ExternalId.arel_table
            matches_external_value = eid_t[:source_type].eq(sti_name).and(eid_t[:value].eq(text))
            client_ids = HmisExternalApis::ExternalId.where(matches_external_value).pluck(:source_id)
            return where unless client_ids.any?

            where.or(arel_table[:id].in(client_ids))
          end

          def mci_cleared?
            return true if create_mci_id
            return true if ac_hmis_mci_ids.exists?

            # Check external_ids in addition to ac_hmis_mci_ids because if the id is unpersisted,
            # it will only be accessible this way
            external_ids.detect { |id| id.namespace == HmisExternalApis::AcHmis::Mci::SYSTEM_ID }.present?
          end

          # MCI after_save hook for attributes that get set by the ClientProcessor.
          attr_accessor :create_mci_id
          attr_accessor :update_mci_attributes
          after_save do
            next unless HmisExternalApis::AcHmis::Mci.enabled?

            if create_mci_id
              self.create_mci_id = nil
              HmisExternalApis::AcHmis::Mci.new.create_mci_id(self)
            end

            # For MCI-linked clients, we notify the MCI any time relevant fields change (name, dob, etc).
            if update_mci_attributes
              self.update_mci_attributes = nil
              trigger_columns = HmisExternalApis::AcHmis::UpdateMciClientJob::MCI_CLIENT_COLS
              relevant_fields_changed = trigger_columns.any? { |field| previous_changes&.[](field) }
              HmisExternalApis::AcHmis::UpdateMciClientJob.perform_later(client_id: id) if relevant_fields_changed
            end
          end

          private def requires_mci_clearance?
            return false unless HmisExternalApis::AcHmis::Mci.enabled?
            # If brand new Client record (NOT in context of an Enrollment), then MCI clearance is required
            return true if new_record?

            # MCI clearance is required unless this client is ONLY enrolled at SO/NBN program(s)
            ptypes = HmisExternalApis::AcHmis::Mci::PROJECT_TYPES_NOT_REQUIRING_CLEARANCE
            so_nbn_enrollment_count = enrollments.with_project_type(ptypes).size
            only_so_nbn_enrollments = so_nbn_enrollment_count.positive? && so_nbn_enrollment_count == enrollments.size

            !only_so_nbn_enrollments
          end

          private def validate_required_fields_for_clearance
            return unless HmisExternalApis::AcHmis::Mci.enabled?

            errors.add :name_data_quality, :invalid, message: 'must be Full Name' unless name_data_quality == 1
            errors.add :dob, :required unless dob.present?
            errors.add :dob_data_quality, :invalid, message: 'must be Full DOB' unless dob_data_quality == 1
          end

          private def validate_first_last
            return unless HmisExternalApis::AcHmis::Mci.enabled?

            # First and Last are required, regardless of context
            errors.add :first_name, :required unless first_name.present?
            errors.add :last_name, :required unless last_name.present?

            # If this client has already cleared MCI, then the DOB/DQ fields must be present, regardless of whether clearance was required in the first place.
            validate_required_fields_for_clearance if mci_cleared?
          end

          private def validate_mci_id_exists
            return unless HmisExternalApis::AcHmis::Mci.enabled?
            return unless requires_mci_clearance?

            # Valid if client has an MCI ID, or is going to create one
            return if mci_cleared?

            # Validate that DOB/DQ fields are there. This is needed so you can't go back and remove fields from a cleared client.
            validate_required_fields_for_clearance

            # Add in some custom options (handled by HmisErrors::Error) so it shows up on the correct fields
            full_msg = HmisExternalApis::AcHmis::Mci::MCI_REQUIRED_MSG
            errors.add :id, :required, attribute_override: :mci_id, readable_attribute: 'MCI ID', full_message: full_msg
          end
        end
      end
    end
  end
end
