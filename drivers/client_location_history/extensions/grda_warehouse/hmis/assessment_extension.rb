###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory::GrdaWarehouse
end

module ClientLocationHistory::GrdaWarehouse::Hmis
  module AssessmentExtension
    extend ActiveSupport::Concern

    included do
      scope :with_location_data, -> do
        where(with_location_data: true)
      end
    end
  end
end
