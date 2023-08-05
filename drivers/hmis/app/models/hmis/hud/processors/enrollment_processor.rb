###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      enrollment = @processor.send(factory_name)

      if attribute_name == 'current_unit'
        assign_unit(value)
      else
        attribute_value = attribute_value_for_enum(graphql_enum(field), value)
        enrollment.assign_attributes(attribute_name => attribute_value)
      end
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
      enrollment&.household_id ||= Hmis::Hud::Base.generate_uuid if enrollment.new_record?
      # TODO: set EnrollmentCoC if there is only 1 option
      # Set HUD metadata
      enrollment&.assign_attributes(
        user: @processor.hud_user,
        data_source_id: @processor.hud_user.data_source_id,
      )
    end

    private def assign_unit(unit_id)
      return unless unit_id.present?

      enrollment = @processor.send(factory_name)
      unit = enrollment.project.units.find(unit_id)
      raise "Unit not found: #{unit_id}" unless unit.present?

      active_unit_occupancy = enrollment.active_unit_occupancy
      # If already assigned to this unit: do nothing
      return if active_unit_occupancy&.unit_id == unit.id

      # If assigned to a different unit: unassign
      enrollment.active_unit_occupancy&.assign_attributes(occupancy_period_attributes: { end_date: Date.current })

      # Assign to specified unit
      enrollment.assign_unit(unit: unit, start_date: Date.current, user: @processor.current_user)
    end
  end
end
