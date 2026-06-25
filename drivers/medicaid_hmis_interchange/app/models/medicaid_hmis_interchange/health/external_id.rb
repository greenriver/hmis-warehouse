###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MedicaidHmisInterchange::Health
  class ExternalId < ::HealthBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  end
end
