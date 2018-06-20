module Health
  class MyPatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :set_patients
    include ClientPathGenerator

    def index
      @q = @patients.ransack(params[:q])
      if params[:q].present?
        @patients = @q.result(distinct: true)
      end
      if params[:filter].present?
        @active_filter = true if params[:filter][:population] != 'all'
        case params[:filter][:population]
        when 'not_engaged'
          @patients = @patients.not_engaged
        when 'no_activities'
          @patients = @patients.engaged.no_qualifying_activities_this_month
        when 'engagement_ending'
          @patients = @patients.engagement_ending
        end
        if params[:filter][:user].present?
          @active_filter = true
          @patients = @patients.where(care_coordinator_id: params[:filter][:user].to_i)
        end
      end
      @patients = @patients.order(last_name: :asc, first_name: :asc).
        page(params[:page].to_i).per(25)
    end
    

    def patient_scope
      if current_user.can_manage_care_coordinators?
        ids = [current_user.id] + current_user.user_care_coordinators.pluck(:care_coordinator_id)
        patient_source.where(care_coordinator_id: ids)
      else
        patient_source.where(care_coordinator_id: current_user.id)
      end
    end

    def set_patients
      @patients = patient_scope
    end
    
    def patient_source
      Health::Patient
    end

    def require_user_has_health_agency!
      return true if current_user.health_agency.present?
      not_authorized!
    end
  end
end