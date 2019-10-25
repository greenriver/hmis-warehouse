###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class MyPatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :set_patients
    include ClientPathGenerator

    def index
      @q = @patients.ransack(params[:q])
      @patients = @q.result(distinct: true) if params[:q].present?
      if params[:filter].present?
        @active_filter = true if params[:filter][:population] != 'all'
        case params[:filter][:population]
        when 'not_engaged'
          @patients = @patients.not_engaged
        when 'no_activities'
          # @patients = @patients.engaged.no_qualifying_activities_this_month
          # @elliot engaged means they would have a qualifying activity?
          @patients = @patients.no_qualifying_activities_this_month
        when 'engagement_ending'
          @patients = @patients.engagement_ending
        end
        if params[:filter][:user].present?
          @active_filter = true
          @patients = @patients.where(care_coordinator_id: params[:filter][:user].to_i)
        end
      end
      respond_to do |format|
        format.html do
          @patients = @patients.order(last_name: :asc, first_name: :asc).
            page(params[:page].to_i).per(25)
        end
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          @patients = @patients.joins(:patient_referral).preload(:patient_referral)
          @tracking_sheet = Health::TrackingSheet.new(@patients)
          render xlsx: :index, filename: "Tracking Sheet #{date}.xlsx"
        end
      end
    end

    def patient_scope
      if current_user.can_manage_care_coordinators?
        ids = [current_user.id] + current_user.user_care_coordinators.pluck(:care_coordinator_id)
        patient_source.where(care_coordinator_id: ids).
          joins(:patient_referral).
          merge(Health::PatientReferral.not_confirmed_rejected)
      else
        patient_source.where(care_coordinator_id: current_user.id).
          joins(:patient_referral).
          merge(Health::PatientReferral.not_confirmed_rejected)
      end
    end

    def set_patients
      @patients = patient_scope
    end

    def patient_source
      Health::Patient
    end

    def require_user_has_health_agency!
      return true if current_user.health_agencies.any?

      not_authorized!
    end
  end
end
