###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ExternalRequestLog < GrdaWarehouseBase
    has_one :external_id
    belongs_to :initiator, polymorphic: true
  end
end
