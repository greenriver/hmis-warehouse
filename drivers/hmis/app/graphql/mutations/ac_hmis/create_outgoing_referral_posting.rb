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
      # the front-end doesn't block submission if there are empty required fields, handle it here
      errors = basic_validation(input)
      return { errors: errors } if errors.any?

      enrollment = Hmis::Hud::Enrollment
        .viewable_by(current_user)
        .find_by(id: input.enrollment_id)
      handle_error('enrollment not found') unless enrollment
      handle_error('access denied') unless current_user.can_manage_outgoing_referrals_for?(enrollment.project)

      project = Hmis::Hud::Project
        .viewable_by(current_user)
        .find_by(id: input.project_id)
      handle_error('project not found') unless project

      errors = validate_unit_type(project, input)
      return { errors: errors } if errors.any?

      referral = HmisExternalApis::AcHmis::Referral.new(
        enrollment: enrollment,
        referral_date: Time.current,
        service_coordinator: current_user.name,
      )
      referral.household_members = enrollment.household_members.preload(:client).map do |member|
        HmisExternalApis::AcHmis::ReferralHouseholdMember.new(
          relationship_to_hoh: member.relationship_to_hoh,
          client_id: member.client.id,
        )
      end

      posting = referral.postings.build(
        status: 'assigned_status',
        project: project,
        unit_type_id: input.unit_type_id,
        data_source: enrollment.data_source,
      )
      posting.current_user = current_user

      posting.transaction do
        referral.save
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

    def basic_validation(input)
      errors = HmisErrors::Errors.new
      errors.add(:project_id, :invalid, message: 'is required') unless input.project_id
      errors.add(:enrollment_id, :invalid, message: 'is required') unless input.enrollment_id
      errors.add(:unit_type_id, :invalid, message: 'is required') unless input.unit_type_id
      errors
    end

    def validate_unit_type(project, input)
      errors = HmisErrors::Errors.new
      valid_by_id = project.units.unoccupied_on.preload(:unit_type).index_by(&:unit_type_id)
      unless valid_by_id.key?(input.unit_type_id.to_i)
        valid_types = valid_by_id.values.map { |u| u.unit_type.description }.sort
        if valid_types.any?
          message = "not valid for the selected project. Valid types are #{valid_types.join(', ')}"
          errors.add(:unit_type, :invalid, message: message)
        else
          errors.add(:project_id, :invalid, message: 'does not have any available units')
        end
      end
      errors
    end
  end
end
