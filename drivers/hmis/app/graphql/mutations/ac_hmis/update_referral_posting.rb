###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      posting = HmisExternalApis::AcHmis::ReferralPosting.active.viewable_by(current_user).find(id)
      handle_error('access denied') unless current_user.can_view_enrollment_details_for?(posting.project)
      handle_error('referral not found') unless posting
      handle_error('connection not configured') if posting.from_link? && !HmisExternalApis::AcHmis::LinkApi.enabled?

      errors = HmisErrors::Errors.new

      # check access based on status
      validation_context = case posting.status
      when 'assigned_status', 'accepted_pending_status'
        :hmis_user_action if current_user.can_manage_incoming_referrals_for?(posting.project)
      when 'denied_pending_status'
        :hmis_admin_action if current_user.can_manage_denied_referrals?
      end
      handle_error('access denied') unless validation_context

      posting.current_user = current_user
      posting.attributes = input.to_params

      posting_status_change = posting.changes['status']

      if posting_status_change == ['assigned_status', 'accepted_pending_status']
        # Similar to query_type.rb:project_can_accept_referral, but returns info about each conflicting enrollment, so the user can fix the errors.
        personal_ids = posting.referral.household_members.map(&:client).pluck(:personal_id)
        # no need to check viewable_by on the enrollments, since we would have already raised 'access denied' above
        conflicting_enrollments = posting.project.enrollments.open_including_wip.where(personal_id: personal_ids)

        unless conflicting_enrollments.empty?
          conflicting_enrollments.each do |e|
            errors.add :base, :invalid, full_message: "#{e.client.full_name} already has an open enrollment in this project (entry date: #{e.entry_date}). Please exit the client if the enrollment is invalid or out-of-date, and otherwise deny the referral."
          end

          return { errors: errors }
        end
      end

      with_logging_transaction(posting) do |logger|
        posting.save(context: validation_context) # context for validations
        errors.add_ar_errors(posting.errors.errors)

        # if moving from assigned to accepted_pending, enroll household and assign to unit
        if errors.empty? && posting_status_change == ['assigned_status', 'accepted_pending_status']
          # choose any available unit of type, error if none available
          if posting.unit_type_id
            unit_to_assign = posting.project&.units&.unoccupied_on&.find_by(unit_type_id: posting.unit_type_id)
            errors.add :base, :invalid, full_message: "Unable to accept this referral because there are no #{posting.unit_type.description} units available." unless unit_to_assign.present?
          end
          raise ActiveRecord::Rollback if errors.any?

          # build new household of WIP enrollments
          household_id ||= Hmis::Hud::Enrollment.generate_household_id
          build_enrollments(posting).each do |enrollment|
            enrollment.household_id = household_id
            if enrollment.valid?
              enrollment.assign_unit(unit: unit_to_assign, start_date: enrollment.entry_date, user: current_user) if posting.unit_type_id
              enrollment.save_in_progress! # this method will unset projectID and calls enrollment.save!
            else
              handle_error('Could not create valid enrollments')
            end
          end
          posting.update!(household_id: household_id)
        end

        # if moving from accepted_pending to denied_pending, remove WIP Enrollments
        if errors.empty? && posting_status_change == ['accepted_pending_status', 'denied_pending_status']
          # This should only happen on a race condition, we don't allow this status change if any members are enrolled
          errors.add :base, :invalid, full_message: 'Cannot move household to denied pending, because some household members have completed intake assessments. Please exit clients instead.' if posting.enrollments.not_in_progress.exists?
          raise ActiveRecord::Rollback if errors.any?

          # Note: not checking for can_delete_enrollments permission because it's not needed for deleting WIP enrollments.
          posting.enrollments.each(&:destroy!)
        end

        raise ActiveRecord::Rollback if errors.any?

        # note, cannot mark postings as accepted in this mutation, only denied. Otherwise we'd need to handle that here
        # too
        posting.exit_origin_household(user: hmis_user) if posting_status_change == ['denied_pending_status', 'denied_status']

        # send to link if:
        # * the referral came from link
        # * status has changed (status will be unchanged if user just updated note)
        send_update(posting, logger) if posting.from_link? && posting_status_change.present?
      end

      return { errors: errors } if errors.any?

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

    def with_logging_transaction(posting)
      logger = HmisExternalApis::OauthDeferredClientLogger.new
      begin
        posting.transaction { yield(logger) }
      ensure
        # ensure errors are persisted
        logger.finalize!
      end
    end

    def send_update(posting, logger)
      # Contact date should only be present when changing to AcceptedPending or DeniedPending
      contact_date = ['accepted_pending_status', 'denied_pending_status'].include?(posting.status) ? Time.current : nil

      Rails.logger.info "Updating status in LINK for posting #{posting.identifier} from posting form"
      HmisExternalApis::AcHmis::UpdateReferralPostingJob.perform_now(
        posting_id: posting.identifier,
        posting_status_id: posting.status_before_type_cast,
        status_note: posting.status_note,
        denied_reason_id: posting.denial_reason_before_type_cast,
        denial_note: posting.denial_note,
        referral_result_id: posting.referral_result_before_type_cast,
        contact_date: contact_date,
        requested_by: current_user.email,
        logger: logger,
      )
    end

    def build_enrollments(posting)
      project = posting.project
      coc_code = project.project_cocs.pluck(:coc_code).first
      raise "No CoC codes for project #{project.id}" unless coc_code.present?

      posting.referral.household_members.preload(:client).map do |member|
        Hmis::Hud::Enrollment.new(
          user: Hmis::Hud::User.from_user(current_user),
          enrollment_coc: coc_code,
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
