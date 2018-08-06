module Health
  class PatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :load_active_agency
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
      end
      @patients = @patients.
        order(last_name: :asc, first_name: :asc).
        page(params[:page].to_i).per(25)

    end

    def load_active_agency
      if params[:agency_id].present?
        @active_agency = current_user.health_agencies.select{|a| a.id.to_s == params[:agency_id]}.first
      end
      if !@active_agency.present?
        @active_agency = current_user.health_agencies.first
      end
    end
    

    def patient_scope 
      patient_source.joins(:health_agency).
        where(agencies: {id: @active_agency.id})
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