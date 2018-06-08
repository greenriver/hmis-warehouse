module Admin::EtoApi
  class AssessmentsController < ApplicationController
    before_action :require_can_manage_assessments!


    def index
      @assessments = assessment_scope.order(site_name: :asc, name: :asc)

    end
    
    def edit 
      @assessment = assessment_scope.find params[:id]
    end
    
    def update 
      @assessment = assessment_scope.find params[:id]
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
        )
    end

  end
end
