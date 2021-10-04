###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ConflictingClientAttributesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    def index
      @attribute_name = attributes.detect { |a| a == params.dig(:report, :attribute) } || 'DOB'
      @clients = client_scope.
        where(id: destination_client_ids).
        order(:LastName, :FirstName).
        page(params[:page])
    end

    def attributes
      ['DOB', 'SSN']
    end
    helper_method :attributes

    def destination_client_ids
      GrdaWarehouse::WarehouseClient.joins(:source).
        merge(client_scope).
        group(:destination_id).
        having(nf('COUNT', [nf('DISTINCT', [c_t[@attribute_name.to_sym]])]).gt(1)).
        distinct.
        select(:destination_id)
    end

    def client_scope
      GrdaWarehouse::Hud::Client.source_visible_to(current_user)
    end
  end
end
