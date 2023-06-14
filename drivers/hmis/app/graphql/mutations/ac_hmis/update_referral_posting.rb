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

      # check access based on status
      validation_context = case posting.status
      when 'assigned_status'
        :hmis_user_action if current_user.can_manage_incoming_referrals_for?(posting.project)
      when 'denied_pending_status'
        :hmis_admin_action if current_user.can_manage_denied_referrals?
      end
      handle_error('access denied') unless validation_context

      posting.current_user = current_user
      posting.attributes = input.to_params

      # if moving from assigned to accepted_pending
      posting_status_change = posting.changes['status']

      posting.transaction do
        posting.save(context: validation_context) # context for validations
        errors.add_ar_errors(posting.errors.errors)

        if errors.empty? && posting_status_change == ['assigned_status', 'accepted_pending_status']
          household_id ||= Hmis::Hud::Enrollment.generate_household_id
          build_enrollments(posting).each do |enrollment|
            enrollment.household_id = household_id
            if enrollment.valid?
              enrollment.save_in_progress # this method will unset projectID and calls enrollment.save!
            else
              handle_error('Could not create valid enrollments')
            end
          end
          posting.update!(household_id: household_id)
        end
        raise ActiveRecord::Rollback if errors.any?
      end
      return { errors: errors } if errors.any?

      # send to link if:
      # * the referral came from link
      # * status has changed (status will be unchanged if user just updated note)
      send_update(posting) if posting.from_link? && posting_status_change.present?
      posting.reload # reload as posting may have been updated from API response

      # resend original referral request
      if posting_status_change == ['denied_pending_status', 'denied_status'] && input.resend_referral_request
        raise unless posting.from_link?
        raise unless posting.referral_request_id

        new_request = posting.referral_request.dup
        HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(new_request)
      end
      { record: posting }
    end

    protected

    def send_update(posting)
      # Contact date should only be present when changing to AcceptedPending or DeniedPending
      contact_date = ['accepted_pending_status', 'denied_pending_status'].include?(posting.status) ? Time.current : nil

      HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
        posting_id: posting.identifier,
        posting_status_id: posting.status_before_type_cast,
        status_note: posting.status_note,
        denied_reason_id: posting.denial_reason_before_type_cast,
        denial_note: posting.denial_note,
        referral_result_id: posting.referral_result_before_type_cast,
        contact_date: contact_date,
        requested_by: current_user.email,
      )
    end

    def build_enrollments(posting)
      project = posting.project
      posting.referral.household_members.preload(:client).map do |member|
        Hmis::Hud::Enrollment.new(
          user: Hmis::Hud::User.from_user(current_user),
          data_source: project.data_source,
          entry_date: Date.current,
          project: project,
          personal_id: member.client.PersonalID,
          RelationshipToHoH: member.relationship_to_hoh_before_type_cast,
        )
      end
    end

    def handle_error(msg)
      raise msg
    end
  end
end
