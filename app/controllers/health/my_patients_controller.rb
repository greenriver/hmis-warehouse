###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
        if params[:filter][:nurse_care_manager_id].present?
          @active_filter = true
          @patients = @patients.where(nurse_care_manager_id: params[:filter][:nurse_care_manager_id].to_i)
        end
      end
      @column = params[:sort] || 'name'
      @direction = params[:direction]&.to_sym || :asc
      respond_to do |format|
        format.html do
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
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          @patients = @patients.joins(:patient_referral).preload(:patient_referral, :recent_cha_form)
          @tracking_sheet = Health::TrackingSheet.new(@patients)
          render(xlsx: 'index', filename: "Tracking Sheet #{date}.xlsx")
        end
      end
    end

    def patient_scope
      population = if current_user.can_manage_care_coordinators?
        ids = [current_user.id] + current_user.user_care_coordinators.pluck(:care_coordinator_id)
        patient_source.
          where(care_coordinator_id: ids).
          or(patient_source.where(nurse_care_manager_id: ids))
      else
        patient_source.
          where(care_coordinator_id: current_user.id).
          or(patient_source.where(nurse_care_manager_id: current_user.id))
      end

      population.
        joins(:patient_referral).
        merge(Health::PatientReferral.assigned.not_disenrolled).
        or(
          population.
            joins(:patient_referral).
            merge(Health::PatientReferral.pending_disenrollment.not_confirmed_rejected),
        )
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

    def require_user_has_health_agency!
      return true if current_user.health_agencies.any?

      not_authorized!
    end
  end
end
