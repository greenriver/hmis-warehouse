###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class RrhDesiredController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    before_action :set_filter

    def index
      @forms = hmis_form_scope.joins(:destination_client).
        merge(client_scope).
        select(*form_columns).
        order(collected_at: :desc)
      @forms = @forms.where(collection_location: @collection_location) if @collection_location
      @forms = @forms.group_by { |f| f.destination_client.id }
    end

    def set_filter
      @collection_location = available_locations.detect { |m| params[:forms].try(:[], :location) == m }
    end

    # NOTE: HmisForm rows tend to be very large, limit the fields we pull
    private def form_columns
      [
        :id,
        :client_id,
        :data_source_id,
        :collection_location,
        :collected_at,
        :staff,
        :staff_email,
      ] + hmis_form_source.rrh_columns
    end

    private def client_scope
      client_source.destination.no_release_on_file
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def hmis_form_source
      GrdaWarehouse::HmisForm
    end

    private def hmis_form_scope
      hmis_form_source.pathways.interested_in_some_rrh
    end

    private def available_locations
      hmis_form_source.pathways.interested_in_some_rrh.
        distinct.
        order(collection_location: :asc).
        pluck(:collection_location)
    end
    helper_method :available_locations
  end
end
