###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class ConflictingClientAttributesController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @attribute_name = attributes.detect { |a| a == params.dig(:report, :attribute)} || 'Gender'
      @clients = []
      destination_client_scope.each do |destination_client|
        if destination_client.source_clients.pluck(@attribute_name).uniq.size > 1
          @clients << destination_client
        end
      end
      @clients = Kaminari.paginate_array(@clients).page(params[:page])
    end

    def attributes
      [
        'Gender',
        'DOB',
        'SSN',
      ]
    end
    helper_method :attributes

    def destination_client_scope
      GrdaWarehouse::Hud::Client.
        destination.
        where(id:
          GrdaWarehouse::WarehouseClient.
            group(:destination_id).
            having('count(destination_id)>1').
            pluck(:destination_id)
        ).
        order(:last_name, :first_name)
    end
  end
end
