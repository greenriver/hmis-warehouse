###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health::He
  class CasesController < HealthController
    include ContactTracingController

    def new
      @case = Health::Tracing::Case.new
    end

    def new_warehouse
      client = GrdaWarehouse::Hud::Client.viewable_by(current_user).find(params[:id].to_i)
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
      @case = Health::Tracing::Case.create(case_data)
      render :edit
    end

    def edit
      @case = Health::Tracing::Case.find(params[:id].to_i)
    end

    def create
      case_data = {
        health_emergency: health_emergency_contact_tracing,
      }
      @case = Health::Tracing::Case.create(case_params.merge(case_data))
      redirect_to edit_health_he_case_path(@case)
    end

    def destroy
      @case = Health::Tracing::Case.find(params[:id].to_i)
      @case.destroy
      redirect_to health_he_search_path
    end

    def update
      @case = Health::Tracing::Case.find(params[:id].to_i)
      case_data = {
        health_emergency: health_emergency_contact_tracing,
      }
      Health::Tracing::Case.update(case_params.merge(case_data))
      redirect_to edit_health_he_case_path(@case)
    end

    def case_params
      params.require(:health_tracing_case).permit(
        :investigator,
        :date_listed,
        :alert_in_epic,
        :complete,
        :date_interviewed,
        :infectious_start_date,
        :testing_date,
        :isolation_start_date,
        :first_name,
        :last_name,
        :aliases,
        :dob,
        :gender,
        :ethnicity,
        :preferred_language,
        :occupation,
        :recent_incarceration,
        :notes,
        race: [],
      )
    end

    def races(client)
      HUD.races.keys.select { |race| client.public_send(race) == 1 }
    end
  end
end
