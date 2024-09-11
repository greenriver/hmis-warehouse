###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :load_active_agency
    before_action :set_patients
    before_action :set_dates, only: [:index]

    include ClientPathGenerator
    include AjaxModalRails::Controller
    include HealthPatientDashboard
    include Search

    def index
      @search, @patients, @active_filter = apply_filter(@patients, params[:filter])

      @column = params[:sort] || 'name'
      @direction = params[:direction]&.to_sym || :asc
      @report = Health::AgencyPerformance.new(range: (@start_date..@end_date), agency_scope: Health::Agency.where(id: @active_agency.id))
      @agencies = @report.agency_counts

      medicaid_ids = @patients.map(&:medicaid_id)
      @patients = patient_source.where(id: @patients.pluck(:id))
      if @column == 'name'
        @patients = @patients.order(last_name: @direction, first_name: @direction)
      else
        sort_order = determine_sort_order(medicaid_ids, @column, @direction)
        @patients = @patients.order_as_specified(sort_order)
      end
      @pagy, @patients = pagy(@patients)
      @scores = calculate_dashboards(medicaid_ids)
    end

    def load_active_agency
      @active_agency = current_user.health_agencies.select { |a| a.id.to_s == params[:entity_id] }.first if params[:entity_id].present?
      @active_agency = current_user.health_agencies.first unless @active_agency.present?
    end

    def patient_scope
      patient_source.joins(:health_agency, :patient_referral).
        merge(Health::Agency.where(id: @active_agency.id)).
        merge(Health::PatientReferral.not_confirmed_rejected).
        distinct
    end

    def set_patients
      @patients = patient_scope
    end

    def patient_source
      Health::Patient
    end

    def detail
      agency_name = params.require(:entity)[:entity_id]
      @section = params.require(:entity)[:section]
      @patient_ids = params.require(:entity)[:patient_ids]&.split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        preload(:care_coordinator).
        order(last_name: :asc, first_name: :asc)

      @agency = Health::Agency.find_by(name: agency_name)
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

    def describe_computations
      path = 'app/views/warehouse_reports/health/agency_performance/README.md'
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations
  end
end
