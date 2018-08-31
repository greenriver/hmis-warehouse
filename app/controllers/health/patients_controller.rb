module Health
  class PatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :load_active_agency
    before_action :set_patients
    before_action :set_dates, only: [:index]

    include WindowClientPathGenerator
    include PjaxModalController

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

      @report = Health::AgencyPerformance.new(range: (@start_date..@end_date), agency_scope: Health::Agency.where(id: @active_agency.id))

      @agencies = @report.agency_counts()

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
      patient_source.joins(:health_agency, :patient_referral).
        where(agencies: {id: @active_agency.id}).
        merge(Health::PatientReferral.not_confirmed_rejected)
    end

    def set_patients
      @patients = patient_scope
    end

    def patient_source
      Health::Patient
    end

    def detail
      @agency_id = params[:agency_id]&.to_i
      @section = params[:section]
      @patient_ids = params[:patient_ids]&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        order(last_name: :asc, first_name: :asc).
        pluck(:client_id, :first_name, :last_name).map do |client_id, first_name, last_name|
          OpenStruct.new(
            client_id: client_id,
            first_name: first_name,
            last_name: last_name
          )
      end

      @agency = Health::Agency.find(@agency_id)

    end

    def set_dates
      @start_date = 1.months.ago.beginning_of_month.to_date
      # for the first few months of the BH CP, the default date range is larger
      if Date.today < '2018-09-01'.to_date
        @end_date = (@start_date + 1.months).end_of_month
      else
        @end_date = @start_date.end_of_month
      end

      @start_date = params[:filter].try(:[], :start_date).presence || @start_date
      @end_date = params[:filter].try(:[], :end_date).presence || @end_date

    end

    def require_user_has_health_agency!
      return true if current_user.health_agencies.any?
      not_authorized!
    end
  end
end