###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class ExternalId < ::HealthBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  end
end
