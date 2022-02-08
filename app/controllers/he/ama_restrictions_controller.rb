###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module He
  class AmaRestrictionsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergencyController

    def create
      user_data = {
        user_id: current_user.id,
        client_id: params[:client_id],
        agency_id: current_user.agency&.id,
        emergency_type: health_emergency,
      }
      @restriction = GrdaWarehouse::HealthEmergency::AmaRestriction.create(restriction_params.merge(user_data))
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def destroy
      @restriction = GrdaWarehouse::HealthEmergency::AmaRestriction.find(params[:id].to_i)
      @restriction.destroy
      flash[:notice] = 'Medical Restriction Activity Removed'
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def restriction_params
      params.require(:grda_warehouse_health_emergency_ama_restriction).
        permit(
          :restricted,
          :note,
        )
    end
  end
end
