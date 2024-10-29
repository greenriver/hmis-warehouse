#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module ClientLocationHistory::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_many :enrollment_location_histories, class_name: 'ClientLocationHistory::Location', through: :enrollments
    end
  end
end
