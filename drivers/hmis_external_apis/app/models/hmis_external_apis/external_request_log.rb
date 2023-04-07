###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# FIXME: Any chance this would be used by processes outside of this driver?
module HmisExternalApis
  class ExternalRequestLog < GrdaWarehouseBase
    has_one :external_id
  end
end
