###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::CreateOutgoingReferralPosting < CleanBaseMutation
    description 'Create outgoing referral posting'

    argument :input, Types::HmisSchema::OutgoingReferralPostingInput, required: false

    field :record, Types::HmisSchema::ReferralPosting, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      handle_error('connection not configured') unless HmisExternalApis::AcHmis::LinkApi.enabled?

      enrollment = Hmis::Hud::Enrollment
        .viewable_by(current_user)
        .find_by(id: input.enrollment_id)
      handle_error('enrollment not found') unless enrollment
      handle_error('access denied') if current_user.can_manage_outgoing_referrals_for?(enrollment.project)

      project = Hmis::Hud::Project
        .viewable_by(current_user)
        .find_by(id: input.project_id)
      handle_error('project not found') unless project

      referral = HmisExternalApis::AcHmis::Referral.new(
        project: project,
      )
      posting = referral.postings.build(
        status: 'assigned_status',
      )

      posting.current_user = current_user
      referral.attributes = input.to_params

      errors = HmisErrors::Errors.new
      posting.transaction do
        referral.save
        errors.add_ar_errors(referral.errors.errors)
        posting.save # context for validations
        errors.add_ar_errors(posting.errors.errors)

        raise ActiveRecord::Rollback if errors.any?
      end
      return { errors: errors } if errors.any?

      { record: posting }
    end

    protected

    def handle_error(msg)
      raise msg
    end
  end
end
