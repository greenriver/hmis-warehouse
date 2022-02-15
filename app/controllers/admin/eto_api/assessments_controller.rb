###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin::EtoApi
  class AssessmentsController < ApplicationController
    before_action :require_can_manage_assessments!

    def index
      @assessments = assessment_scope.order(
        name: :asc,
        assessment_id: :asc,
        site_name: :asc,
      )
    end

    def edit
      @assessment = assessment_scope.find(params[:id])
    end

    def update
      @assessment = assessment_scope.find(params[:id])
      if @assessment.update(assessment_params)
        redirect_to action: :index
        flash[:notice] = "Touch Point: #{@assessment.name} was successfully updated."
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def assessment_source
      GrdaWarehouse::HMIS::Assessment
    end

    def assessment_scope
      assessment_source.all
    end

    def assessment_params
      params.require(:grda_warehouse_hmis_assessment).
        permit(
          :fetch,
          :active,
          :confidential,
          :exclude_from_window,
          :health,
          :vispdat,
          :pathways,
          :ssm,
          :health_case_note,
          :health_has_qualifying_activities,
          :hud_assessment,
          :triage_assessment,
          :rrh_assessment,
          :covid_19_impact_assessment,
          :with_location_data,
        )
    end
  end
end
