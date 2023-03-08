# frozen_string_literal: true

module AssessmentHelpers
  def build_minimum_values(definition, assessment_date)
    item = definition.assessment_date_item
    field_name = item.field_name
    field_name = 'Exit.exitDate' if field_name == 'exitDate'
    field_name = 'Enrollment.entryDate' if field_name == 'entryDate'
    {
      values: { item.link_id => assessment_date },
      hud_values: { field_name => assessment_date },
    }
  end

  def custom_form_attributes(role, assessment_date)
    definition = Hmis::Form::Definition.find_by(role: role)
    raise "No definition for role #{role}" unless definition.present?

    {
      definition: definition,
      **build_minimum_values(definition, assessment_date),
    }
  end
end
