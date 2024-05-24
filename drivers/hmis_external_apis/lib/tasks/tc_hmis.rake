namespace :tc_hmis do
  # rails driver:hmis_external_apis:tc_hmis:generate_synthetic_ce_assessments_for_dce_assessments
  desc 'one-time task to create synthetic CE assessments for DCE custom assessments'
  task :generate_synthetic_ce_assessments_for_dce_assessments, [] => :environment do |_task, _args|
    definition = Hmis::Form::Definition.where(identifier: 'diversion-crisis-assessment').first!
    form_processors = Hmis::Form::FormProcessor.where(definition: definition)
    custom_assessments = Hmis::Hud::CustomAssessment.where(
      id: form_processors.select(:custom_assessment_id),
    )
    HmisExternalApis::TcHmis::Importers::SyntheticCeAssessmentsForCustomAssessment.new.perform(
      custom_assessments: custom_assessments,
      assessment_type: 3, # in person
      assessment_level: 1, # crisis needs assessment
      prioritization_status: 1, # placed on prioritization list
    )
  end
end
