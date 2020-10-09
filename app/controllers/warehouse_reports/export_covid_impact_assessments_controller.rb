###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ExportCovidImpactAssessmentsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    def index
      assessment_ids = {}
      GrdaWarehouse::HmisForm.covid_19_impact_assessments.order(collected_at: :desc).
        pluck(:id, :client_id).each do |id, client_id|
          assessment_ids[client_id] ||= id
        end
      @clients = client_scope.where(id: assessment_ids.keys)
      @assessments = GrdaWarehouse::HmisForm.covid_19_impact_assessments.
        where(id: assessment_ids.values).index_by(&:client_id)
    end

    private def client_scope
      client_source.viewable_by(current_user)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
