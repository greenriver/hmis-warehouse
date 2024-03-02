###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#
module HmisExternalApis::ExternalForms
  class FormDefinition < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_definitions'

    has_many :submissions, class_name: 'HmisExternalApis::ExternalForms::FormSubmission'

    # create or update a from definition from a file. Helpful for development
    def self.from_file(page_name)
      filename = Rails.root.join("drivers/hmis_external_apis/lib/external_forms/#{page_name}.json")
      data = JSON.parse(File.read(filename))

      definition = where(name: page_name).first_or_initialize
      title = data['name']
      definition.update!( title: title, data: data)
      definition
    end

    def publish!
      HmisExternalApis::PublishExternalFormsJob.new.perform(id)
    end

    def validate_json!
      Hmis::Form::Definition.validate_json(data) do |msg|
        raise msg
      end
    end
  end
end
