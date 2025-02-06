###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class SplitHousehold < CleanBaseMutation
    argument :splitting_enrollment_inputs, [Types::HmisSchema::EnrollmentRelationshipInput], required: true

    field :new_household, Types::HmisSchema::Household, null: false
    field :remaining_household, Types::HmisSchema::Household, null: false

    def resolve(splitting_enrollment_inputs:)
      map_enrollment_id_to_relationship = splitting_enrollment_inputs.map { |e| [e.enrollment_id, e.relationship_to_hoh] }.to_h

      splitting_enrollment_ids = map_enrollment_id_to_relationship.keys
      splitting_enrollments = Hmis::Hud::Enrollment.
        where(id: splitting_enrollment_ids).
        viewable_by(current_user).
        includes(:household, :project)
      access_denied! unless splitting_enrollments.size == splitting_enrollment_inputs.size

      project = splitting_enrollments.map(&:project).uniq.sole
      access_denied! unless current_permission?(permission: :can_split_households, entity: project)

      donor_household = splitting_enrollments.map(&:household).uniq.sole
      remaining_enrollments = donor_household.enrollments.where.not(id: splitting_enrollment_ids)

      raise 'Splitting all clients to a new household is invalid' if remaining_enrollments.empty?
      raise 'This operation would leave behind a household with no HoH, which is not allowed' unless remaining_enrollments.exists?(relationship_to_hoh: 1)

      donor_before_state = donor_household.snapshot_household_state
      new_household_id = Hmis::Hud::Base.generate_uuid

      Hmis::Hud::Enrollment.transaction do
        splitting_enrollments.each do |enrollment|
          enrollment.household_id = new_household_id
          enrollment.relationship_to_hoh = map_enrollment_id_to_relationship[enrollment.id.to_s]

          enrollment.active_unit_occupancy&.assign_attributes(occupancy_period_attributes: { end_date: Date.current })

          enrollment.save!
        end

        donor_household.reload
        donor_after_state = donor_household.snapshot_household_state

        event = Hmis::HouseholdEvent.new
        event.user = current_user
        event.household = donor_household
        event.event_type = Hmis::HouseholdEvent::SPLIT
        event.event_details = {
          'receiving_household_id': new_household_id,
          'before': donor_before_state,
          'after': donor_after_state,
        }
        event.save!

        remaining_enrollments.invalidate_processing!
      end

      {
        new_household: splitting_enrollments.first.reload.household,
        remaining_household: donor_household,
      }
    end
  end
end
