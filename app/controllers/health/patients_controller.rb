###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
      @patients = @q.result(distinct: true) if params[:q].present?
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

      @agencies = @report.agency_counts

      @patients = @patients.
        order(last_name: :asc, first_name: :asc).
        page(params[:page].to_i).per(25)
    end

    def load_active_agency
      @active_agency = current_user.health_agencies.select { |a| a.id.to_s == params[:agency_id] }.first if params[:agency_id].present?
      @active_agency = current_user.health_agencies.first unless @active_agency.present?
    end

    def patient_scope
      patient_source.joins(:health_agency, :patient_referral).
        where(agencies: { id: @active_agency.id }).
        merge(Health::PatientReferral.not_confirmed_rejected)
    end

    def set_patients
      @patients = patient_scope
    end

    def patient_source
      Health::Patient
    end

    def detail
      @agency_id = ProtectedId::Encoder.decode(params.require(:agency)[:agency_id])
      @section = params.require(:agency)[:section]
      @patient_ids = params.require(:agency)[:patient_ids]&.split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        order(last_name: :asc, first_name: :asc).
        pluck(:client_id, :first_name, :last_name).map do |client_id, first_name, last_name|
        OpenStruct.new(
          client_id: client_id,
          first_name: first_name,
          last_name: last_name,
        )
      end

      @agency = Health::Agency.find(@agency_id)
    end

    def set_dates
      @start_date = Date.current.beginning_of_month.to_date
      @end_date = @start_date.end_of_month

      @start_date = params[:filter].try(:[], :start_date).presence || @start_date
      @end_date = params[:filter].try(:[], :end_date).presence || @end_date

      return unless @start_date.to_date > @end_date.to_date

      new_start = @end_date
      @end_date = @start_date
      @start_date = new_start
    end

    def require_user_has_health_agency!
      return true if current_user.health_agencies.any?

      not_authorized!
    end
  end
end
