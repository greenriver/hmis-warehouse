###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients::Youth
  class PscFeedbackSurveysController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!
    before_action :set_client
    before_action :set_psc_feedback_survey, only: [:edit, :update, :destroy]

    def new
      @modal_size = :xl
      @psc_feedback_survey = psc_feedback_survey_source.new(conversation_on: Date.current)
    end

    def create
      @psc_feedback_survey = psc_feedback_survey_source.new(user_id: current_user.id, client: @client)
      @psc_feedback_survey.update(psc_feedback_survey_params)
      respond_with(@psc_feedback_survey, location: polymorphic_path(youth_intakes_path_generator))
    end

    def edit
      @modal_size = :xl
    end

    def update
      @psc_feedback_survey.update(psc_feedback_survey_params)
      respond_with(@psc_feedback_survey, location: polymorphic_path(youth_intakes_path_generator))
    end

    def destroy
      @psc_feedback_survey.destroy
      respond_with(@psc_feedback_survey, location: polymorphic_path(youth_intakes_path_generator))
    end

    def psc_feedback_survey_params
      params.require(:grda_warehouse_youth_psc_feedback_survey).permit(
        :conversation_on,
        :location,
        :listened_to_me,
        :cared_about_me,
        :knowledgeable,
        :i_was_included,
        :i_decided,
        :supporting_my_needs,
        :sensitive_to_culture,
        :would_return,
        :more_calm_and_control,
        :satisfied,
        :comments,
      )
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def set_psc_feedback_survey
      @psc_feedback_survey = psc_feedback_survey_scope.find(params[:id].to_i)
    end

    def psc_feedback_survey_source
      GrdaWarehouse::Youth::PscFeedbackSurvey
    end

    def psc_feedback_survey_scope
      psc_feedback_survey_source.visible_by?(current_user)
    end
  end
end
