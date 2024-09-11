###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

      # has_one :earliest_client_location_history, -> do
      #   one_for_column(
      #     :located_on,
      #     source_arel_table: ClientLocationHistory::Location.arel_table,
      #     group_on: :client_id,
      #   )
      # end, class_name: 'ClientLocationHistory::Location'
    end
  end
end
