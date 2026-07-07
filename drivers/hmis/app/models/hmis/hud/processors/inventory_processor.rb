###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class InventoryProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::Inventory
    end

    def information_date(_)
    end
  end
end
