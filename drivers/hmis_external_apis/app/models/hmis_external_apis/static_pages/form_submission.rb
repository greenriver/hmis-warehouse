###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::StaticPages
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_static_form_submissions'
  end
end
