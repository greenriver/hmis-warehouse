###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class JoinHouseholds < BaseMutation
    argument :receiving_household_id, ID, required: true
    argument :joining_enrollment_inputs, [Types::HmisSchema::JoiningEnrollmentInput], required: true

    field :receiving_household, Types::HmisSchema::Household, null: false
    field :donor_household, Types::HmisSchema::Household, null: true # For frontend expediency, also return the donor household, if there are any remaining members

    def resolve(receiving_household_id:, joining_enrollment_inputs:)
      receiving_enrollments = Hmis::Hud::Enrollment.
        viewable_by(current_user).
        includes(:project).
        where(household_id: receiving_household_id)
      access_denied! if receiving_enrollments.empty?

      receiving_enrollment = receiving_enrollments.find { |e| e.relationship_to_hoh == 1 } || receiving_enrollments.first

      receiving_project = receiving_enrollments.map(&:project).uniq.sole
      access_denied! unless current_permission?(permission: :can_split_households, entity: receiving_project)

      map_enrollment_id_to_relationship = joining_enrollment_inputs.map { |e| [e.enrollment_id, e.relationship_to_hoh] }.to_h

      joining_enrollment_ids = map_enrollment_id_to_relationship.keys
      joining_enrollments = Hmis::Hud::Enrollment.
        joins(:project).
        viewable_by(current_user).
        where(id: joining_enrollment_ids)
      access_denied! unless joining_enrollments.count == joining_enrollment_inputs.count

      raise 'Cannot merge enrollments from another project' unless joining_enrollments.pluck(:project_pk).uniq.sole == receiving_project.id

      donor_household = joining_enrollments.map(&:household).uniq.sole
      remaining_enrollments = Hmis::Hud::Enrollment.
        where(household_id: donor_household.household_id).
        where.not(id: joining_enrollment_ids)
      remaining_hoh = remaining_enrollments.any? { |enrollment| enrollment.relationship_to_hoh == 1 }
      raise 'This operation would leave behind a household with no HoH, which is not allowed' unless remaining_enrollments.empty? || remaining_hoh

      # This works for the present-tense, tracking current unit occupancy, but could be improved to better accommodate past data correction
      units = receiving_enrollments.map { |enrollment| enrollment.active_unit_occupancy&.unit }.compact.uniq

      receiving_before_state = snapshot(receiving_enrollments)
      donor_before_state = snapshot(donor_household.enrollments)

      Hmis::Hud::Enrollment.transaction do
        joining_enrollments.each_with_index do |enrollment, index|
          enrollment.update!(
            household_id: receiving_household_id,
            relationship_to_hoh: map_enrollment_id_to_relationship[enrollment.id.to_s],
          )

          # Whether or not the receiving household has a unit assignment, clear the current unit assignment for the joining enrollments
          enrollment.active_unit_occupancy&.assign_attributes(occupancy_period_attributes: { end_date: Date.current })

          unless units.empty?
            unit = units[index % units.length] # If the receiving household has multiple units, pick any, deterministically
            enrollment.assign_unit(unit: unit, start_date: Date.current, user: current_user)
          end

          enrollment.save!
        end

        receiving_enrollment.reload
        donor_household.reload if remaining_enrollments.any?

        joining_event = Hmis::HouseholdEvent.new
        joining_event.user = current_user
        joining_event.household = receiving_enrollment.household
        joining_event.event_type = Hmis::HouseholdEvent::JOIN
        joining_event.event_details = {
          'donorHouseholdId': donor_household.household_id,
          'before': receiving_before_state,
          'after': snapshot(receiving_enrollment.household.enrollments),
        }
        joining_event.save!

        leaving_event = Hmis::HouseholdEvent.new
        leaving_event.user = current_user
        leaving_event.household = donor_household
        leaving_event.event_type = Hmis::HouseholdEvent::SPLIT
        leaving_event.event_details = {
          'receivingHouseholdId': receiving_household_id,
          'before': donor_before_state,
          'after': snapshot(remaining_enrollments),
        }
        leaving_event.save!
      end

      {
        receiving_household: receiving_enrollment.household,
        donor_household: remaining_enrollments.first&.household,
      }
    end

    private def snapshot(enrollments)
      enrollments.map do |enrollment|
        {
          'enrollmentId': enrollment.id,
          'relationshipToHoh': enrollment.relationship_to_hoh,
        }
      end
    end
  end
end
