###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::UpdateReferralPosting < CleanBaseMutation
    description 'Update a referral posting'

    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ReferralPostingInput, required: false

    field :record, Types::HmisSchema::ReferralPosting, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:)
      handle_error('connection not configured') unless HmisExternalApis::AcHmis::LinkApi.enabled?

      posting = HmisExternalApis::AcHmis::ReferralPosting.active.viewable_by(current_user).find(id)
      handle_error('referral not found') unless posting

      errors = HmisErrors::Errors.new
      project = posting.project
      allowed = current_user.can_manage_incoming_referrals_for?(posting.project)
      handle_error('access denied') unless allowed

      posting.current_user = current_user
      posting.attributes = input.to_params

      # if moving from assigned to accepted_pending
      accepting_referral = posting.changes['status'] == ['assigned_status', 'accepted_pending_status']

      posting.transaction do
        posting.save
        errors.add_ar_errors(posting.errors.errors)

        if errors.empty? && accepting_referral
          # not sure if this extra check is needed
          handle_error('access denied') unless current_user.permissions_for?(project, :can_enroll_clients)
          build_enrollments(posting).each do |enrollment|
            if enrollment.valid?
              enrollment.save_in_progress # calls enrollment.save!
            else
              errors += enrollment.errors.errors
            end
          end
        end
        raise ActiveRecord::Rollback if errors.any?
      end
      return { errors: errors } if errors.any?

      # send to link if:
      # * the referral came from link
      # * status has changed from "assigned" (if user just updated note)
      send_update(posting) if posting.from_link? && !posting.assigned_status?
      posting.reload # reload as posting may have been updated from API response
      { record: posting }
    end

    protected

    def send_update(posting)
      HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
        posting_id: posting.identifier,
        posting_status_id: posting.status_before_type_cast,
        denied_reason_id: posting.denied_reason_before_typecast,
        denied_reason_text: posting.denied_reason_text,
        status_note: posting.status_note,
        contact_date: now,
        requested_by: current_user.email,
      )
    end

    def build_enrollments(posting)
      posting.referral.household_members.preload(:client).map do |member|
        Hmis::Hud::Enrollment.new(
          user: current_user,
          data_source: project.data_source,
          entry_date: entry_date,
          project: posting.project,
          personal_id: member.client.PersonalID,
          household_id: member.household_id,
        )
      end
    end

    def handle_error(msg)
      raise msg
    end
  end
end
