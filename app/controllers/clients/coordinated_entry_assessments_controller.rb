###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class CoordinatedEntryAssessmentsController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_access_ce_assessment_list!, only: [:index, :show]
    before_action :require_can_create_or_modify_ce_assessment!, except: [:index, :show]
    before_action :set_client
    before_action :set_assessment, except: [:new, :create, :index]
    before_action :require_can_edit_ce_assessment!, only: [:destroy]
    after_action :log_client

    def index
      @assessments = @client.ce_assessments.
        order(created_at: :desc)
      respond_with(@assessments)
    end

    def show
      if @assessment.visible_by?(current_user)
        respond_with(@assessment)
      else
        not_authorized!
      end
    end

    def edit
      render :show if @assessment.show_as_readonly?
    end

    def new
      @assessment = build_assessment
    end

    def destroy
      @assessment.transaction do
        @assessment.destroy
        GrdaWarehouse::CoordinatedEntryAssessment::Base.ensure_active(@assessment.client)
      end
      respond_with(@assessment, location: client_coordinated_entry_assessments_path(@client))
    end

    def create
      if @client.ce_assessments.in_progress.none?
        @assessment = build_assessment
      else
        @assessment = @client.ce_assessments.in_progress.first
      end
      if params[:commit] == 'Complete'
        @assessment.assign_attributes(assessment_params)
        @assessment.make_active!(current_user)
      else
        @assessment.update(assessment_params)
      end
      respond_with(@assessment, location: client_coordinated_entry_assessments_path(client_id: @client.id))
    end

    def update
      if params[:commit] == 'Complete'
        @assessment.assign_attributes(assessment_params)
        @assessment.make_active!(current_user)
      else
        @assessment.assign_attributes(assessment_params.merge(user_id: current_user.id))
        @assessment.save(validate: false)
      end
      respond_with(@assessment, location: client_coordinated_entry_assessments_path(client_id: @client.id))
    end

    private def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    private def set_assessment
      @assessment = assessment_source.find(params[:id].to_i)
    end

    private def assessment_source
      GrdaWarehouse::CoordinatedEntryAssessment::Base
    end

    private def build_assessment
      assessment_type = GrdaWarehouse::CoordinatedEntryAssessment::Base.available_types.detect { |m| m == params[:type] } || 'GrdaWarehouse::CoordinatedEntryAssessment::Individual'
      @client.ce_assessments.build(user_id: current_user.id, type: assessment_type, assessor_id: current_user.id)
    end

    private def assessment_params
      # this will be based off of the model name
      param_key = @assessment.class.model_name.param_key
      params.require(param_key).permit(*@assessment.class.allowed_parameters)
    end

    private def title_for_show
      "#{@client.name} - #{_ 'Coordinated Entry Assessment'}"
    end

    def flash_interpolation_options
      { resource_name: 'Coordinated Entry Assessment' }
    end
  end
end
