###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      enrollment = @processor.send(factory_name)

      return assign_unit(value) if attribute_name == 'current_unit'

      attributes = case attribute_name
      when 'move_in_addresses'
        # delete enrollment.addresses, this might happen if move-in-date is unset
        tx_value = value == Base::HIDDEN_FIELD_VALUE ? nil : value
        construct_nested_attributes(field, tx_value, additional_attributes: related_move_in_address_attributes)
      else
        attribute_value = attribute_value_for_enum(graphql_enum(field), value)
        { attribute_name => attribute_value }
      end
      enrollment.assign_attributes(attributes)
    end

    def factory_name
      :enrollment_factory
    end

    def schema
      Types::HmisSchema::Enrollment
    end

    def information_date(_)
      # Enrollments don't have an information date to be set
    end

    def assign_metadata
      enrollment = @processor.send(factory_name)

      # Create Household ID if not present. Should only be the case if this is a new Enrollment creation.
      enrollment.household_id ||= Hmis::Hud::Base.generate_uuid if enrollment.new_record?

      # Try to infer EnrollmentCoC
      enrollment.enrollment_coc ||= determine_enrollment_coc(enrollment)

      # Set HUD metadata
      enrollment.assign_attributes(
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
      )
    end

    private def determine_enrollment_coc(enrollment)
      # If non-HoH member, return the HoH's CoC
      unless enrollment.head_of_household?
        hoh_coc_code = enrollment.household_members.heads_of_households.first&.enrollment_coc
        return hoh_coc_code if hoh_coc_code.present?
      end

      # If Project only operates in one CoC, return that CoC
      project_cocs = enrollment.project&.uniq_coc_codes || []
      return project_cocs.first if project_cocs.size == 1

      nil
    end

    private def assign_unit(unit_id)
      return unless unit_id.present?

      enrollment = @processor.send(factory_name)
      unit = enrollment.project.units.find(unit_id)
      raise "Unit not found: #{unit_id}" unless unit.present?
      raise 'Cannot assign unit to exited enrollment' if enrollment.exit&.exit_date.present?

      active_unit_occupancy = enrollment.active_unit_occupancy
      # If already assigned to this unit: do nothing
      return if active_unit_occupancy&.unit_id == unit.id

      # If assigned to a different unit: unassign
      enrollment.active_unit_occupancy&.assign_attributes(occupancy_period_attributes: { end_date: Date.current })

      # Assign to specified unit
      enrollment.assign_unit(unit: unit, start_date: Date.current, user: @processor.current_user)
    end

    def related_move_in_address_attributes
      {
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
        PersonalID: @processor.send(factory_name).client.PersonalID,
        # currently all enrollment addresses are move-in
        enrollment_address_type: Hmis::Hud::CustomClientAddress::ENROLLMENT_MOVE_IN_TYPE,
      }
    end
  end
end
