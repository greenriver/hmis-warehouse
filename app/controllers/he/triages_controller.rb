###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module He
  class TriagesController < ApplicationController
    include ClientDependentControllers
    include HealthEmergencyController
    before_action :require_can_edit_health_emergency_screening!

    def create
      user_data = {
        user_id: current_user.id,
        client_id: params[:client_id],
        agency_id: current_user.agency&.id,
        emergency_type: health_emergency,
      }
      @triage = GrdaWarehouse::HealthEmergency::Triage.create(triage_params.merge(user_data))
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def destroy
      @triage = GrdaWarehouse::HealthEmergency::Triage.find(params[:id].to_i)
      @triage.destroy
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def triage_params
      params.require(:grda_warehouse_health_emergency_triage).
        permit(
          :location,
          :exposure,
          :symptoms,
          :first_symptoms_on,
          :referred_on,
          :referred_to,
          :notes,
        )
    end
  end
end
