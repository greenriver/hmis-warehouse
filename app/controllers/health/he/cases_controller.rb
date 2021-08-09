###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::He
  class CasesController < HealthController
    include IndividualContactTracingController

    before_action :set_case, only: [:show, :edit, :update, :destroy]
    before_action :set_client, only: [:show, :edit, :update, :destroy]

    def new
      client = GrdaWarehouse::Hud::Client.destination_visible_to(current_user).find_by(id: params[:client_id].to_i)
      case_data = {}
      if client.present?
        case_data = {
          health_emergency: health_emergency_contact_tracing,
          client_id: client.id,
          first_name: client.first_name,
          last_name: client.last_name,
          dob: client.DOB,
          gender: client.Gender,
          race: races(client),
          ethnicity: client.Ethnicity,
        }
      end
      @case = Health::Tracing::Case.new(case_data)
    end

    def show
    end

    def edit
    end

    def create
      case_data = {
        health_emergency: health_emergency_contact_tracing,
      }
      @case = Health::Tracing::Case.create(case_params.merge(case_data))
      redirect_to edit_health_he_case_path(@case)
    end

    def destroy
      @case.destroy
      redirect_to health_he_search_path
    end

    def update
      case_data = {
        health_emergency: health_emergency_contact_tracing,
      }
      @case.update(case_params.merge(case_data))
      redirect_to health_he_case_path(@case)
    end

    private def set_case
      @case = Health::Tracing::Case.find(params[:id].to_i)
    end

    def case_params
      params.require(:health_tracing_case).permit(
        :client_id,
        :investigator,
        :date_listed,
        :alert_in_epic,
        :complete,
        :date_interviewed,
        :infectious_start_date,
        :day_two,
        :other_symptoms,
        :testing_date,
        :isolation_start_date,
        :first_name,
        :last_name,
        :phone,
        :aliases,
        :dob,
        :gender,
        :ethnicity,
        :preferred_language,
        :occupation,
        :recent_incarceration,
        :notes,
        :vaccinated,
        :vaccination_complete,
        vaccine: [],
        vaccination_dates: [],
        race: [],
        symptoms: [],
      )
    end

    def races(client)
      HUD.races.keys.select { |race| client.public_send(race) == 1 }
    end
  end
end
