###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientLocationHistory::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_many :enrollment_location_histories, class_name: 'ClientLocationHistory::Location', through: :enrollments
    end
  end
end
