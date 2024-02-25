###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::StaticPages
  class Form < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_static_forms'
  end
end
