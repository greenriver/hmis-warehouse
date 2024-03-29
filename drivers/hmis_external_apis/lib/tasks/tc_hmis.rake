namespace :tc_hmis do
  # rails driver:hmis_external_apis:tc_hmis:seed_external_forms

  desc 'Seed external form definitions. Helpful for development and general setup'
  task :seed_external_forms, [] => :environment do
    path = Rails.root.join('drivers/hmis/lib/form_data/tarrant_county/external_forms')
    Dir.glob("#{path}/*.json") do |file_path|
      file_name = File.basename(file_path, '.json')
      definition = Hmis::Form::Definition.where(identifier: "tchc_#{file_name}").first_or_initialize
      definition.definition = JSON.parse(File.read(file_path))
      Hmis::Form::Definition.validate_json(definition.definition) { |msg| raise msg }
      definition.role = :EXTERNAL_FORM
      definition.title = definition.definition['name']
      definition.status = 'draft'
      definition.version = 0
      definition.external_form_object_key = "tchc/#{file_name}"
      definition.save!
      HmisExternalApis::PublishExternalFormsJob.new.perform(definition.id)
    end
  end

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
