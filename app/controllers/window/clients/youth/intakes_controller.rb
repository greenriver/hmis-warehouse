module Window::Clients::Youth
  class IntakesController < ApplicationController
    include WindowClientPathGenerator
    include PjaxModalController

    before_action :require_can_access_youth_intake_list!
    before_action :require_can_edit_some_youth_intakes!, only: [:edit, :udate, :new, :create, :destroy]

    before_action :set_client
    before_action :set_intake, only: [:show, :edit, :update, :destroy]

    after_action :log_client


    def index
      @intakes = @client.youth_intakes.merge(intake_scope)
      @case_managements = @client.case_managements.order(engaged_on: :desc, created_at: :desc)
      @direct_financial_assistances = @client.direct_financial_assistances.order(provided_on: :desc, created_at: :desc)
      @youth_referrals = @client.youth_referrals.order(referred_on: :desc, created_at: :desc)

      @referral = @client.youth_referrals.build(referred_on: Date.today)
      @assistance = @client.direct_financial_assistances.build(provided_on: Date.today)
    end

    def show
    end

    def new
      new_source = if @client.youth_intakes.merge(intake_scope).exists?
        @client.youth_intakes.merge(intake_scope).order(updated_at: :desc).first
      else
        intake_source.new
      end
      @intake = new_source
      @intake.staff_name = current_user.name
      @intake.staff_email = current_user.email
      @intake.engagement_date = Date.today
      @intake.client_dob ||= @client.DOB
    end

    def create
      @intake = intake_source.new(user_id: current_user.id, client_id: @client.id)
      @intake.assign_attributes(intake_params)
      @intake.client_race = intake_params[:client_race].select(&:present?).to_json
      @intake.disabilities = intake_params[:disabilities].select(&:present?).to_json

      set_other_options
      @intake.save
      if @intake.errors.any?
        flash[:error] = 'Please correct errors in the intake form.'
      end
      respond_with(@intake, location: polymorphic_path(youth_intakes_path_generator))
    end

    def destroy
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

    def set_client
      @client = GrdaWarehouse::Hud::Client.destination.find(params[:client_id].to_i)
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
      unless @intake.how_hear_options.include?(@intake.how_hear)
        @intake.other_how_hear = @intake.how_hear
        @intake.how_hear = 'Other...'
      end
    end

    private def set_other_options
      @intake.client_primary_language = @intake.other_language if @intake.client_primary_language == 'Other...'
      @intake.how_hear = @intake.other_how_hear if @intake.how_hear == 'Other'
    end

    private def intake_params
      params.require(:grda_warehouse_youth_intake_entry).permit(
        :other_staff_completed_intake,
        :client_dob,
        :staff_name,
        :staff_email,
        :engagement_date,
        :exit_date,
        :unaccompanied,
        :street_outreach_contact,
        :housing_status,
        :other_agency_involvement,
        :owns_cell_phone,
        :secondary_education,
        :attending_college,
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
        client_race: [],
        disabilities: [],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Youth Intake' }
    end

  end
end