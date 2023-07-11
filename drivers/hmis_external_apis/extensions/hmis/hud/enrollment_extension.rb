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

          def accept_referral!(current_user:)
            return unless head_of_household?
            return unless HmisExternalApis::AcHmis::LinkApi.enabled?

            # Posting can only be accepted if it is AcceptedPending or Closed (if re-opening exited enrollment)
            posting = source_postings.find_by(status: ['accepted_pending_status', 'closed_status'])
            return unless posting.present? && posting.identifier.present?

            posting.status = 20 # accepted
            posting.referral_result = 1 # successful result
            posting.save!
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
            return unless posting.present? && posting.identifier.present?

            posting.status = 13 # closed
            posting.save!
            HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
              posting_id: posting.identifier,
              posting_status_id: posting.status_before_type_cast,
              requested_by: current_user.email,
            )
          end
        end
      end
    end
  end
end
