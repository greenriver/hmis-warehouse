###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PatientGoalsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include HealthGoal

    before_action :set_client
    before_action :set_hpc_patient

    def index
      @modal_size = :xl
      @goals = @patient.hpc_goals
    end

    def after_path
      polymorphic_path(goals_path_generator)
    end

    def goal_form_path
      if @goal.new_record?
        polymorphic_path(goals_path_generator)
      else
        polymorphic_path(goal_path_generator, id: @goal.id)
      end
    end
    helper_method :goal_form_path

    def new_goal_path
      polymorphic_path([:new] + goal_path_generator)
    end
    helper_method :new_goal_path

    def edit_goal_path(goal)
      polymorphic_path([:edit] + goal_path_generator, id: goal.id)
    end
    helper_method :edit_goal_path

    def delete_goal_path(goal)
      polymorphic_path(goal_path_generator, id: goal.id)
    end
    helper_method :delete_goal_path

    protected def title_for_show
      "#{@client.name} - Health - Goals"
    end
  end
end
