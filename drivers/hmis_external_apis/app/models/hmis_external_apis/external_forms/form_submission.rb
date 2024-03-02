###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_submissions'
    belongs_to :form_definition, class_name: 'HmisExternalApis::ExternalForms::FormDefinition'
  end
end
