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

  def assessment_detail_attributes(role, assessment_date)
    definition = Hmis::Form::Definition.find_by(role: role)
    raise "No definition for role #{role}" unless definition.present?

    {
      data_collection_stage: Types::HmisSchema::Enums::AssessmentRole.as_data_collection_stage(role.to_s),
      definition: definition,
      role: role,
      **build_minimum_values(definition, assessment_date),
    }
  end
end
