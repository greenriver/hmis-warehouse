###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange
  module GrdaWarehouse::Hud::ClientExtension
    extend ActiveSupport::Concern

    included do
      has_one :external_health_id, class_name: 'MedicaidHmisInterchange::Health::ExternalId'
    end
  end
end
