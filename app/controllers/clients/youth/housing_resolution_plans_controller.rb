###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients::Youth
  class HousingResolutionPlansController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!
    before_action :set_client
    before_action :set_housing_resolution_plan, only: [:edit, :update, :destroy]

    def new
      @modal_size = :xl
      @housing_resolution_plan = housing_resolution_plan_source.new(
        planned_on: Date.current,
        staff_name: current_user.name,
      )
      @housing_resolution_plan.pronouns ||= @client.housing_resolution_plans.last&.pronouns
    end

    def create
      @housing_resolution_plan = housing_resolution_plan_source.new(user_id: current_user.id, client: @client)
      @housing_resolution_plan.update(housing_resolution_plan_params)
      respond_with(@housing_resolution_plan, location: polymorphic_path(youth_intakes_path_generator))
    end

    def edit
      @modal_size = :xl
    end

    def update
      @housing_resolution_plan.update(housing_resolution_plan_params)
      respond_with(@housing_resolution_plan, location: polymorphic_path(youth_intakes_path_generator))
    end

    def destroy
      @housing_resolution_plan.destroy
      respond_with(@housing_resolution_plan, location: polymorphic_path(youth_intakes_path_generator))
    end

    def housing_resolution_plan_params
      params.require(:grda_warehouse_youth_housing_resolution_plan).permit(
        :pronouns,
        :planned_on,
        :staff_name,
        :location,
        :chosen_resolution,
        :temporary_resolution,
        :plan_description,
        :action_steps,
        :backup_plan,
        :next_checkin,
        :how_to_contact,
        :psc_attempted,
        :psc_why_not,
        :resolution_achieved,
        :resolution_why_not,
        :problem_solving_point,
        :housing_crisis_cause_other,
        :factor_employment_income,
        :factor_family_supports,
        :factor_social_supports,
        :factor_life_skills,
        housing_crisis_causes: [],
      )
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    def set_housing_resolution_plan
      @housing_resolution_plan = housing_resolution_plan_scope.find(params[:id].to_i)
    end

    def housing_resolution_plan_source
      GrdaWarehouse::Youth::HousingResolutionPlan
    end

    def housing_resolution_plan_scope
      housing_resolution_plan_source.visible_by?(current_user)
    end
  end
end
