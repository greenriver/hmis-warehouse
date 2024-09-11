###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory::GrdaWarehouse
end

module ClientLocationHistory::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :enrollment_location_histories, class_name: 'ClientLocationHistory::Location', as: :source
      # has_many :direct_enrollment_location_histories, class_name: 'ClientLocationHistory::Location', inverse_of: :enrollment
      #
      # has_one :earliest_enrollment_location_history, -> do
      #   one_for_column(
      #     :located_on,
      #     direction: :asc,
      #     source_arel_table: ClientLocationHistory::Location.arel_table,
      #     group_on: :enrollment_id,
      #   )
      # end, class_name: 'ClientLocationHistory::Location', inverse_of: :enrollment
    end
  end
end
