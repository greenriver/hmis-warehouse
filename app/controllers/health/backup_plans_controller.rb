###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class BackupPlansController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_backup_plan, only: [:edit, :destroy, :update]

    def index
      # For errors in new/edit forms
      @backup_plan = backup_plan_source.new
      @backup_plans = @patient.backup_plans.order(plan_created_on: :desc, id: :asc)
    end

    def new
      @backup_plan = backup_plan_source.new
      @button_label = 'Add Backup Plan'
      @form_url = polymorphic_path(health_path_generator + [:backup_plans], client_id: @client.id)
    end

    def edit
      @button_label = 'Save Backup Plan'
      @form_url = polymorphic_path(health_path_generator + [:backup_plan], client_id: @client.id)
    end

    def update
      @button_label = 'Save Backup Plan'
      @form_url = polymorphic_path(health_path_generator + [:backup_plan], client_id: @client.id)
      @backup_plan.assign_attributes(backup_plan_params)
      if request.xhr?
        if @backup_plan.valid?
          Health::BackupPlanSaver.new(backup_plan: @backup_plan, user: current_user).update
        else
          render 'create'
        end
      else
        Health::BackupPlanSaver.new(backup_plan: @backup_plan, user: current_user).update
        respond_with(@backup_plan, location: polymorphic_path(health_path_generator + [:backup_plans], client_id: @client.id))
      end
    end

    def create
      @button_label = 'Add Backup Plan'
      @form_url = polymorphic_path(health_path_generator + [:backup_plans], client_id: @client.id)
      @backup_plan = @patient.backup_plans.build(backup_plan_params)
      if request.xhr?
        if @backup_plan.valid?
          Health::BackupPlanSaver.new(backup_plan: @backup_plan, user: current_user).update
        else
          render 'create'
        end
      else
        Health::BackupPlanSaver.new(backup_plan: @backup_plan, user: current_user).update
        respond_with(@backup_plan, location: polymorphic_path(health_path_generator + [:backup_plans], client_id: @client.id))
      end
    end

    def destroy
      @backup_plan.destroy
      respond_with(@backup_plan, location: polymorphic_path(health_path_generator + [:backup_plans], client_id: @client.id)) unless request.xhr?
    end

    def backup_plan_params
      params.require(:health_backup_plan).permit(
        :description,
        :backup_plan,
        :person,
        :phone,
        :address,
        :plan_created_on,
      )
    end

    def backup_plan_source
      Health::BackupPlan
    end

    def set_backup_plan
      @backup_plan = backup_plan_source.find(params[:id].to_i)
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end

    def flash_interpolation_options
      { resource_name: 'Backup Plan' }
    end

    protected def title_for_show
      "#{@client.name} - Health - Backup Plans"
    end
  end
end
