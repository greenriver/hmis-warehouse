###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory::GrdaWarehouse
end

module ClientLocationHistory::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :client_location_histories, class_name: 'ClientLocationHistory::Location'
    end
  end
end
