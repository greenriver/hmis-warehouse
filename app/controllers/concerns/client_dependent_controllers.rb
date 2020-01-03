###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ClientDependentControllers
  extend ActiveSupport::Concern

  included do
    def client_source
      GrdaWarehouse::Hud::Client
    end

    def searchable_client_scope
      # client_source.destination.searchable_by(current_user)
      client_source.destination.where(
        client_source.arel_table[:id].in(
          Arel.sql(
            GrdaWarehouse::WarehouseClient.joins(:source).
              merge(GrdaWarehouse::Hud::Client.searchable_by(current_user)).
              select(:destination_id).to_sql,
          ),
        ).
        or(
          client_source.arel_table[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.searchable_by(current_user).select(:id).to_sql)),
        ),
      )
    end
  end
end
