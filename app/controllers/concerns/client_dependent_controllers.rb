###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDependentControllers
  extend ActiveSupport::Concern

  included do
    def client_source
      GrdaWarehouse::Hud::Client
    end

    def searchable_client_scope(id: nil)
      # client_source.destination.searchable_by(current_user)
      scope = client_source.destination
      scope = scope.where(id: id) if id

      # Query the source clients
      source_client_query = GrdaWarehouse::WarehouseClient.joins(:source).
        merge(GrdaWarehouse::Hud::Client.searchable_by(current_user)).
        select(:destination_id)
      source_client_query = source_client_query.where(destination_id: id) if id

      # Query the destination clients
      destination_client_query = GrdaWarehouse::Hud::Client.searchable_by(current_user)
      destination_client_query = destination_client_query.where(id: id) if id

      scope.where(
        client_source.arel_table[:id].in(
          Arel.sql(source_client_query.to_sql),
        ).
        or(
          client_source.arel_table[:id].in(Arel.sql(destination_client_query.select(:id).to_sql)),
        ),
      )
    end
  end
end
