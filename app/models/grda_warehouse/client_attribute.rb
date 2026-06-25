###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ClientAttribute < GrdaWarehouseBase
    has_paper_trail

    belongs_to :destination_client,
               optional: true,
               class_name: 'GrdaWarehouse::Hud::Client',
               foreign_key: :client_id
  end
end
