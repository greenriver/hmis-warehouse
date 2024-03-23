###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# track external publication of a form definition
module HmisExternalApis::ExternalForms
  class FormPublication < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_publications'
    belongs_to :definition, class_name: 'Hmis::Form::Definition'
  end
end
