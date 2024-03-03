namespace :tc_hmis do
  # rails driver:hmis_external_apis:tc_hmis:seed_external_forms

  desc 'Seed external form definitions. Helpful for development and general setup'
  task :seed_external_forms, [] => :environment do
    path = Rails.root.join('drivers/hmis/lib/form_data/tarrant_county/external_forms')
    Dir.glob("#{path}/*.json") do |file_path|
      file_name = File.basename(file_path, '.json')
      definition = Hmis::Form::Definition.where(identifier: "tchc#{file_name}").first_or_initialize
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
end
