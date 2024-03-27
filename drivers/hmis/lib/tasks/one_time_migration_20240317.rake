# frozen_string_literal: true

desc 'One time data migration to populate custom assessment definition identifiers'
# rails driver:hmis:populate_assessment_definition_identifiers_20231121
task populate_assessment_definition_identifiers_20231121: [:environment] do
  scope = Hmis::Hud::CustomAssessment.
    where(form_definition_identifier: nil).
    preload(form_processor: :definition)

  Hmis::Hud::CustomAssessment.transaction do
    scope.find_each do |assessment|
      identifier = assessment.form_processor&.definition&.identifier
      # perhaps should use CustomAssessment.DataCollectionStage if identifier is null?
      next unless identifier

      assessment.update!(form_definition_identifier: identifier)
    end
  end
end
