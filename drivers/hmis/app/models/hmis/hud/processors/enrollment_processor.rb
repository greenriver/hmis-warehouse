###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentProcessor < Base
    def process(field, value)
      attribute_name = ar_attribute_name(field)
      attribute_value = attribute_value_for_enum(graphql_enum(field), value)
      enrollment = @processor.send(factory_name)

      # TODO(#185510437): assign unit if specified
      enrollment.assign_attributes({ attribute_name => attribute_value })
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
  end
end
