###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients::Youth
  class IntakesController < ApplicationController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include ClientDependentControllers

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!, except: [:index, :show]

    before_action :set_client
    before_action :set_intake, only: [:show, :edit, :update, :destroy]
    before_action :require_can_delete_youth_intake!, only: [:remove_all_youth_data]

    after_action :log_client

    def index
      @intakes = @client.youth_intakes.merge(intake_scope)
      @case_managements = @client.case_managements.
        merge(GrdaWarehouse::Youth::YouthCaseManagement.visible_by?(current_user)).
        order(engaged_on: :desc, created_at: :desc)
      @direct_financial_assistances = @client.direct_financial_assistances.
        merge(GrdaWarehouse::Youth::DirectFinancialAssistance.visible_by?(current_user)).
        order(provided_on: :desc, created_at: :desc)
      @dfa_sum = @direct_financial_assistances.sum(:amount)
      @youth_referrals = @client.youth_referrals.
        merge(GrdaWarehouse::Youth::YouthReferral.visible_by?(current_user)).
        order(referred_on: :desc, created_at: :desc)
      @follow_ups = @client.youth_follow_ups.
        merge(GrdaWarehouse::Youth::YouthFollowUp.visible_by?(current_user)).
        order(contacted_on: :desc, created_at: :desc)
      @housing_resolution_plans = @client.housing_resolution_plans.
        merge(GrdaWarehouse::Youth::HousingResolutionPlan.visible_by?(current_user)).
        order(planned_on: :desc, created_at: :desc)
      @psc_feedback_surveys = @client.psc_feedback_surveys.
        merge(GrdaWarehouse::Youth::PscFeedbackSurvey.visible_by?(current_user)).
        order(conversation_on: :desc, created_at: :desc)

      @referral = @client.youth_referrals.build(referred_on: Date.current)
      @assistance = @client.direct_financial_assistances.build(provided_on: Date.current)
    end

    def show
    end

    def new
      new_source = if @client.youth_intakes.merge(intake_scope).exists?
        @client.youth_intakes.merge(intake_scope).order(updated_at: :desc).first.dup
      else
        intake_source.new
      end
      @intake = new_source
      @intake.id = nil
      @intake.exit_date = nil
      @intake.staff_name = current_user.name
      @intake.staff_email = current_user.email
      @intake.engagement_date = Date.current
      @intake.client_dob ||= @client.DOB
    end

    def create
      @intake = intake_source.new(user_id: current_user.id, client_id: @client.id)
      @intake.assign_attributes(intake_params)

      set_other_options
      @intake.save
      flash[:error] = 'Please correct errors in the intake form.' if @intake.errors.any?
      respond_with(@intake, location: polymorphic_path(youth_intakes_path_generator))
    end

    def destroy
      @intake.destroy
      respond_with(@intake, location: polymorphic_path(youth_intakes_path_generator))
    end

    def remove_all_youth_data
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
      if @client.present?
        @client.youth_intakes.destroy_all
        @client.case_managements.destroy_all
        @client.direct_financial_assistances.destroy_all
        @client.youth_referrals.destroy_all
        @client.youth_follow_ups.destroy_all
        # TODO: This does not remove the client from the Youth DataSource

        flash[:notice] = "All Youth information for #{@client.name} has been removed."
        redirect_to client_youth_intakes_path(@client)
      else
        not_authorized!
      end
    end

    def edit
      use_other_options
    end

    def update
      @intake.assign_attributes(intake_params)
      set_other_options

      @intake.save
      respond_with(@intake, location: polymorphic_path(youth_intakes_path_generator))
    end

    def follow_up_due_on
      return unless @intakes.ongoing.exists?

      last_contact = [
        @intakes.ongoing.first&.engagement_date,
        @case_managements.first&.engaged_on,
        @direct_financial_assistances.first&.provided_on,
        @youth_referrals.first&.referred_on,
        @follow_ups.first&.contacted_on,
      ].compact.max

      cut_off_date = Date.current - 3.months - 1.week
      last_contact + 3.months if last_contact.present? && last_contact <= cut_off_date
    end

    def set_client
      @client = destination_searchable_client_scope.find(params[:client_id].to_i)
    end

    private def intake_source
      GrdaWarehouse::YouthIntake::Entry
    end

    private def intake_scope
      intake_source.visible_by?(current_user)
    end

    private def set_intake
      @intake = intake_scope.find(params[:id].to_i)
    end

    private def use_other_options
      unless @intake.languages.include?(@intake.client_primary_language)
        @intake.other_language = @intake.client_primary_language
        @intake.client_primary_language = 'Other...'
      end
      return if @intake.how_hear_options.include?(@intake.how_hear)

      @intake.other_how_hear = @intake.how_hear
      @intake.how_hear = 'Other...'
    end

    private def set_other_options
      @intake.client_primary_language = @intake.other_language if @intake.client_primary_language == 'Other...'
      @intake.how_hear = @intake.other_how_hear if @intake.other_referral?

      # Clean arrays to remove blanks
      @intake.client_race = intake_params[:client_race].select(&:present?)
      @intake.disabilities = intake_params[:disabilities].select(&:present?)
      @intake.other_agency_involvements = intake_params[:other_agency_involvements].select(&:present?)
    end

    private def intake_params
      params.require(:grda_warehouse_youth_intake_entry).permit(
        :first_name,
        :last_name,
        :ssn,
        :other_staff_completed_intake,
        :client_dob,
        :staff_name,
        :staff_email,
        :engagement_date,
        :exit_date,
        :unaccompanied,
        :street_outreach_contact,
        :housing_status,
        :owns_cell_phone,
        :secondary_education,
        :attending_college,
        :college_pilot,
        :graduating_college,
        :health_insurance,
        :requesting_financial_assistance,
        :staff_believes_youth_under_24,
        :client_gender,
        :client_lgbtq,
        :client_ethnicity,
        :client_primary_language,
        :pregnant_or_parenting,
        :how_hear,
        :needs_shelter,
        :referred_to_shelter,
        :in_stable_housing,
        :stable_housing_zipcode,
        :youth_experiencing_homelessness_at_start,
        :other_language,
        :other_how_hear,
        :turned_away,
        other_agency_involvements: [],
        client_race: [],
        disabilities: [],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Youth Intake' }
    end
  end
end
