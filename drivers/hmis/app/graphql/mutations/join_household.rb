###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class JoinHousehold < CleanBaseMutation
    argument :receiving_household_id, ID, required: true
    argument :joining_enrollment_inputs, [Types::HmisSchema::EnrollmentRelationshipInput], required: true

    field :receiving_household, Types::HmisSchema::Household, null: false
    field :donor_household, Types::HmisSchema::Household, null: true # Will be null if there are no remaining members

    def resolve(receiving_household_id:, joining_enrollment_inputs:)
      # note: viewable_by takes care of filtering by data source via project with_access
      receiving_household = Hmis::Hud::Household.viewable_by(current_user).find_by(household_id: receiving_household_id)
      access_denied! unless receiving_household
      receiving_enrollments = receiving_household.enrollments
      receiving_project = receiving_household.project
      access_denied! unless current_permission?(permission: :can_split_households, entity: receiving_project)

      # The mutation input is a list, so convert it to a hashmap for ease of access
      map_enrollment_id_to_relationship = joining_enrollment_inputs.map { |e| [e.enrollment_id, e.relationship_to_hoh] }.to_h

      joining_enrollment_ids = map_enrollment_id_to_relationship.keys
      joining_enrollments = Hmis::Hud::Enrollment.
        where(project: receiving_project). # can only join from household in same project
        where(id: joining_enrollment_ids)
      access_denied! unless joining_enrollments.count == joining_enrollment_inputs.count
      raise 'Cannot join from multiple households' unless joining_enrollments.map(&:household_id).uniq.size == 1

      donor_household = joining_enrollments.first.household

      remaining_enrollments = donor_household.enrollments - joining_enrollments
      remaining_hoh_exists = remaining_enrollments.any? { |enrollment| enrollment.relationship_to_hoh == 1 }
      raise 'This operation would leave behind a household with no HoH, which is not allowed' unless remaining_enrollments.empty? || remaining_hoh_exists

      # If the receiving household is assigned to any unit(s), assign the joining enrollments to the same unit.
      # This works for the present-tense, but could be improved to better accommodate past data correction.
      receiving_unit = receiving_enrollments.joins(:current_unit).first&.current_unit

      receiving_before_state = receiving_household.snapshot_household_state
      donor_before_state = donor_household.snapshot_household_state

      Hmis::Hud::Enrollment.transaction do
        joining_enrollments.each do |enrollment|
          enrollment.household_id = receiving_household_id
          enrollment.relationship_to_hoh = map_enrollment_id_to_relationship[enrollment.id.to_s]

          # Whether or not the receiving household has a unit assignment, clear the joining enrollment's current unit assignment
          enrollment.active_unit_occupancy&.assign_attributes(occupancy_period_attributes: { end_date: Date.current })
          enrollment.assign_unit(unit: receiving_unit, start_date: Date.current, user: current_user) if receiving_unit

          enrollment.save!
        end

        receiving_household.reload
        receiving_after_state = receiving_household.snapshot_household_state

        donor_after_state = []
        if remaining_enrollments.any?
          donor_household.reload
          donor_after_state = donor_household.snapshot_household_state
        end

        joining_event = Hmis::HouseholdEvent.new
        joining_event.user = current_user
        joining_event.household = receiving_household
        joining_event.event_type = Hmis::HouseholdEvent::JOIN
        joining_event.event_details = {
          'donor_household_id': donor_household.household_id,
          'before': receiving_before_state,
          'after': receiving_after_state,
        }

        leaving_event = Hmis::HouseholdEvent.new
        leaving_event.user = current_user
        leaving_event.household = donor_household
        leaving_event.event_type = Hmis::HouseholdEvent::SPLIT
        leaving_event.event_details = {
          'receiving_household_id': receiving_household_id,
          'before': donor_before_state,
          'after': donor_after_state,
        }
        Hmis::HouseholdEvent.import!([joining_event, leaving_event])
      end

      {
        receiving_household: receiving_household,
        donor_household: remaining_enrollments.any? ? donor_household : nil,
      }
    end
  end
end
