###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class MyPatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :set_patients
    include ClientPathGenerator
    include HealthPatientDashboard

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
      respond_to do |format|
        format.html do
          medicaid_ids = @patients.map(&:medicaid_id)
          @patients = patient_source.where(id: @patients.pluck(:id))
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

      patient_ids_with_payable_qas_in_month = population.
        joins(:qualifying_activities).
        merge(Health::QualifyingActivity.payable.in_range(Date.current.beginning_of_month..Date.tomorrow)).
        pluck(:id)

      population.
        joins(:patient_referral).
        merge(Health::PatientReferral.assigned.not_disenrolled).
        or(
          population.
            joins(:patient_referral).
            merge(Health::PatientReferral.pending_disenrollment.not_confirmed_rejected).
            where.not(id: patient_ids_with_payable_qas_in_month),
        )
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
