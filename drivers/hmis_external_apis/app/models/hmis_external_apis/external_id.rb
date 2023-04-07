###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# FIXME: Any chance this would be used by processes outside of this driver?
module HmisExternalApis
  class ExternalId < GrdaWarehouseBase
    validates :value, presence: true
    belongs_to :source, polymorphic: true
    belongs_to :remote_credential, class_name: 'GrdaWarehouse::RemoteCredential'
    belongs_to :external_request_log
  end
end
