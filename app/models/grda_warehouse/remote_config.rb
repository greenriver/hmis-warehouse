###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class RemoteConfig < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :remote_credential
    scope :active, -> do
      SandboxMode.filter(where(active: true))
    end
  end
end
