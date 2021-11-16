###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

        if params[:filter][:user].present?
          @active_filter = true
          user_id = if params[:filter][:user] == 'unassigned'
            nil
          else
            params[:filter][:user].to_i
          end

          @patients = @patients.where(care_coordinator_id: user_id)
        end

        if params[:filter][:nurse_care_manager_id].present?
          @active_filter = true
          nurse_care_manager_id = if params[:filter][:nurse_care_manager_id] == 'unassigned'
            nil
          else
            params[:filter][:nurse_care_manager_id].to_i
          end

          @patients = @patients.where(nurse_care_manager_id: nurse_care_manager_id)
        end
      end

      @column = params[:sort] || 'name'
      @direction = params[:direction]&.to_sym || :asc
      @report = Health::AgencyPerformance.new(range: (@start_date..@end_date), agency_scope: Health::Agency.where(id: @active_agency.id))
      @agencies = @report.agency_counts

      medicaid_ids = @patients.map(&:medicaid_id)
      if @column == 'name'
        @patients = @patients.order(last_name: @direction, first_name: @direction)
      else
        sort_order = determine_sort_order(medicaid_ids, @column, @direction)
        @patients = @patients.order_as_specified(sort_order)
      end
      @patients = @patients.page(params[:page].to_i).per(25)
      @scores = calculate_dashboards(medicaid_ids)
    end

    def load_active_agency
      @active_agency = current_user.health_agencies.select { |a| a.id.to_s == params[:agency_id] }.first if params[:agency_id].present?
      @active_agency = current_user.health_agencies.first unless @active_agency.present?
    end

    def patient_scope
      patient_source.joins(:health_agency, :patient_referral).
        merge(Health::Agency.where(id: @active_agency.id)).
        merge(Health::PatientReferral.not_confirmed_rejected).
        distinct
    end

    def sort_options
      sort_options = [
        {
          column: 'name',
          direction: :asc,
          title: 'Name (last, first) A-Z',
        },
        {
          column: 'name',
          direction: :desc,
          title: 'Name (last, first) Z-A',
        },
      ]

      Rails.application.config.patient_dashboards.map do |dashboard|
        dashboard_sort_options = dashboard[:calculator].constantize.dashboard_sort_options
        sort_options << dashboard_sort_options if dashboard_sort_options.present?
      end

      sort_options
    end
    helper_method :sort_options

    def calculate_dashboards(medicaid_ids)
      Rails.application.config.patient_dashboards.map do |dashboard|
        [
          dashboard[:title],
          dashboard[:calculator].constantize.new(medicaid_ids).to_map,
        ]
      end.to_h
    end

    def determine_sort_order(medicaid_ids, column, direction)
      Rails.application.config.patient_dashboards.map do |dashboard|
        sort_order = dashboard[:calculator].constantize.new(medicaid_ids).sort_order(column, direction)
        return sort_order if sort_order.present?
      end
      raise 'Unknown sort column'
    end

    def set_patients
      @patients = patient_scope
    end

    def patient_source
      Health::Patient
    end

    def detail
      @agency_id = params.require(:agency)[:agency_id]&.to_i
      @section = params.require(:agency)[:section]
      @patient_ids = params.require(:agency)[:patient_ids]&.split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        preload(:care_coordinator).
        order(last_name: :asc, first_name: :asc)

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
