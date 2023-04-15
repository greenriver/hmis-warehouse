###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://github.com/greenriver/hmis-warehouse/pull/2933/files#r1164091887
# A local entity's identity in an external system (such as an MCI ID)
# NOTE: The ID values are not necessarily unique. For example two clients
# can share the same MCI ID
module HmisExternalApis
  class ExternalId < GrdaWarehouseBase
    belongs_to :external_request_log, optional: true
    belongs_to :remote_credential, class_name: 'GrdaWarehouse::RemoteCredential'
    belongs_to :source, polymorphic: true

    validates :value, presence: true
  end
end
