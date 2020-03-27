###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module He
  class ClinicalsController < ApplicationController
    include ClientDependentControllers
    include HealthEmergencyController
    before_action :require_can_edit_health_emergency_clinical!

    def test
      user_data = {
        user_id: current_user.id,
        client_id: params[:client_id],
        agency_id: current_user.agency.id,
      }
      @test = GrdaWarehouse::HealthEmergency::Test.create(test_params.merge(user_data))
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def test_params
      params.require(:grda_warehouse_health_emergency_test).
        permit(
          :location,
          :test_requested,
          :tested_on,
          :result,
        )
    end

    def isolation
      user_data = {
        user_id: current_user.id,
        client_id: params[:client_id],
        agency_id: current_user.agency.id,
      }
      @isolation = GrdaWarehouse::HealthEmergency::Isolation.create(isolation_params.merge(user_data))
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def isolation_params
      params.require(:grda_warehouse_health_emergency_isolation).
        permit(
          :isolation_requested_at,
          :location,
          :started_on,
          :ended_on,
          :scheduled_to_end_on,
        )
    end

    def quarantine
      user_data = {
        user_id: current_user.id,
        client_id: params[:client_id],
        agency_id: current_user.agency.id,
      }
      @quarantine = GrdaWarehouse::HealthEmergency::Quarantine.create(quarantine_params.merge(user_data))
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def quarantine_params
      params.require(:grda_warehouse_health_emergency_quarantine).
        permit(
          :isolation_requested_at,
          :location,
          :started_on,
          :ended_on,
          :scheduled_to_end_on,
        )
    end

    def destroy_test
      @test = GrdaWarehouse::HealthEmergency::Test.find(params[:id].to_i)
      @test.destroy
      flash[:notice] = "#{@test.title} Activity Removed"
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end

    def destroy_isolation
      @isolation = GrdaWarehouse::HealthEmergency::IsolationBase.find(params[:id].to_i)
      @isolation.destroy
      flash[:notice] = "#{@isolation.title} Activity Removed"
      redirect_to polymorphic_path(['client_he', health_emergency], client_id: @client)
    end
  end
end
