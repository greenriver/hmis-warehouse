module Admin::EtoApi
  class AssessmentsController < ApplicationController
    before_action :require_can_manage_assessments!


    def index
      @assessments = assessment_scope.order(site_name: :asc, name: :asc)

    end

    def assessment_source
      GrdaWarehouse::HMIS::Assessment
    end

    def assessment_scope
      assessment_source.all
    end

  end
end