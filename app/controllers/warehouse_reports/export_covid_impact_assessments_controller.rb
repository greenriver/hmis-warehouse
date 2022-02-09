###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        joins(:destination_client).select(:id, :site_id, :assessment_id, :client_id, :data_source_id).find_each do |form|
          assessment_ids[form.destination_client.id] ||= form.id
        end
      @clients = client_scope.where(id: assessment_ids.keys)
      @assessments = GrdaWarehouse::HmisForm.covid_19_impact_assessments.
        where(id: assessment_ids.values).joins(:destination_client).
        select(
          :id,
          :client_id,
          :data_source_id,
          :total_subsidy,
          :subsidy_months,
          :monthly_rent_total,
          :number_of_bedrooms,
          :percent_ami,
          :household_type,
          :household_size,
        ).
        index_by do |form|
          form.destination_client.id
        end
    end

    private def client_scope
      client_source.destination_visible_to(current_user)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
