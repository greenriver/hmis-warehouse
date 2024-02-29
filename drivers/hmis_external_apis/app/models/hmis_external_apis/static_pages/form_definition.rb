###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#
module HmisExternalApis::StaticPages
  class FormDefinition < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_static_form_definition'

    has_many :submissions, class_name: 'HmisExternalApis::StaticPages::FormSubmission'

    # create or update a from definition from a file. Helpful for development
    def self.from_file(page_name)
      filename = Rails.root.join("drivers/hmis_external_apis/lib/static_page_forms/#{page_name}.json")
      data = JSON.parse(File.read(filename))

      definition = where(name: page_name).first_or_initialize
      title = data['name']
      definition.update!( title: title, data: data)
      definition
    end

    def publish!
      HmisExternalApis::PublishStaticFormsJob.new.perform(id)
    end

    def validate_json!
      Hmis::Form::Definition.validate_json(data) do |msg|
        raise msg
      end
    end
  end
end
