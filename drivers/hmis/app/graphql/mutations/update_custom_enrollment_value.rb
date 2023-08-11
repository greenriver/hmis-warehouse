###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateCustomEnrollmentValue < BaseMutation
    argument :enrollment_id, ID, required: true
    argument :custom_data_element_definition_id, ID, required: true
    argument :value_float, Float, required: false
    argument :value_integer, Integer, required: false
    argument :value_boolean, Boolean, required: false
    argument :value_string, String, required: false
    argument :value_text, String, required: false
    argument :value_date, GraphQL::Types::ISO8601Date, required: false

    field :enrollment, Types::HmisSchema::Enrollment, null: false

    def resolve(enrollment_id:, custom_data_element_definition_id:, **value_kwargs)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)
      raise 'Enrollment not found' unless enrollment.present?
      raise 'Access denied' unless current_user.permissions_for?(enrollment, :can_edit_enrollments)

      no_value = value_kwargs.compact_blank.empty?

      cded = Hmis::Hud::CustomDataElementDefinition.find_by(id: custom_data_element_definition_id)
      raise 'Custom element must be tied to Enrollment' unless cded.owner_type == 'Hmis::Hud::Enrollment'
      raise 'Custom element cannot be updated at occurrence' unless cded.at_occurrence
      raise 'Updating repeating element at occurrence is not yet supported' if cded.repeats

      custom_value = Hmis::Hud::CustomDataElement.where(
        data_element_definition: cded,
        data_source_id: enrollment.data_source_id,
        owner: enrollment,
      ).first_or_initialize

      # If there was no value and there is nothing already saved, do nothing & return.
      return { enrollment: enrollment, errors: [] } if no_value && custom_value.new_record?

      custom_value.assign_attributes(**value_kwargs, user: hmis_user)
      custom_value.save!
      enrollment.reload
      { enrollment: enrollment, errors: [] }
    end
  end
end
