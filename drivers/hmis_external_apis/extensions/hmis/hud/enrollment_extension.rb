###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module Hmis
    module Hud
      module EnrollmentExtension
        extend ActiveSupport::Concern

        included do
          has_many :external_referrals, class_name: 'HmisExternalApis::AcHmis::Referral', dependent: :destroy
          has_many :source_postings, **hmis_relation(:HouseholdID), class_name: 'HmisExternalApis::AcHmis::ReferralPosting', inverse_of: :enrollments

          validate :validate_client_mci, on: :form_submission, if: :new_record?

          def accept_referral!(current_user:)
            return unless head_of_household?
            return unless HmisExternalApis::AcHmis::LinkApi.enabled?

            # Posting can only be accepted if it is AcceptedPending or Closed (if re-opening exited enrollment)
            posting = source_postings.find_by(status: ['accepted_pending_status', 'closed_status'])
            return unless posting.present?

            posting.status = 20 # accepted
            posting.referral_result = 1 # successful result
            posting.save!
            return unless posting.identifier.present? # HMIS Admin-assigned posting

            HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
              posting_id: posting.identifier,
              posting_status_id: posting.status_before_type_cast,
              referral_result_id: posting.referral_result_before_type_cast,
              requested_by: current_user.email,
            )
          end

          def close_referral!(current_user:)
            return unless head_of_household?
            return unless HmisExternalApis::AcHmis::LinkApi.enabled?

            posting = source_postings.find_by(status: 'accepted_status')
            return unless posting.present?

            posting.status = 13 # closed
            posting.save!
            return unless posting.identifier.present? # HMIS Admin-assigned posting

            HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
              posting_id: posting.identifier,
              posting_status_id: posting.status_before_type_cast,
              requested_by: current_user.email,
            )
          end

          # When creating a new enrollment, validate presence of MCI on client
          def validate_client_mci
            return unless HmisExternalApis::AcHmis::Mci.enabled? && client.present?

            # If enrolling at SO or ES NBN project, MCI is not required.
            return if HmisExternalApis::AcHmis::Mci::PROJECT_TYPES_NOT_REQUIRING_CLEARANCE.include?(project.project_type)

            # Client has an MCI ID, or is going to create one
            return if client.ac_hmis_mci_ids.exists? || client.create_mci_id

            # Add in some custom options (handled by HmisErrors::Error) so it shows up on the correct fields
            full_msg = if client.persisted?
              HmisExternalApis::AcHmis::Mci::MCI_REQUIRED_FOR_ENROLLMENT_MSG
            else
              HmisExternalApis::AcHmis::Mci::MCI_REQUIRED_MSG
            end
            errors.add :id, :required, attribute_override: :mci_id, readable_attribute: 'MCI ID', full_message: full_msg
          end
        end
      end
    end
  end
end
