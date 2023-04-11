###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ExternalId < GrdaWarehouseBase
    belongs_to :external_request_log
    belongs_to :remote_credential, class_name: 'GrdaWarehouse::RemoteCredential'
    belongs_to :source, polymorphic: true

    validates :value, presence: true
  end
end
