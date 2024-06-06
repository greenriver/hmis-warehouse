###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    include ArelHelper
    include Search

    def index
      @search, @patients, @active_filter = apply_filter(@patients, params[:filter])

      @column = params[:sort] || 'name'
      @direction = params[:direction]&.to_sym || :asc
      respond_to do |format|
        format.html do
          ids = @patients.pluck(:id, :medicaid_id)
          medicaid_ids = ids.map(&:last)
          @patients = patient_source.where(id: ids.map(&:first)) # This removes the need to re-process the complicated patient query
          if @column == 'name'
            @patients = @patients.order(last_name: @direction, first_name: @direction)
          else
            sort_order = determine_sort_order(medicaid_ids, @column, @direction)
            @patients = @patients.order_as_specified(sort_order)
          end
          @pagy, @patients = pagy(@patients)
          @scores = calculate_dashboards(medicaid_ids)
        end
        format.xlsx do
          date = Date.current.strftime('%Y-%m-%d')
          @patients = @patients.joins(:patient_referral).
            preload(:patient_referral, :recent_cha_form, client: :processed_service_history)
          @tracking_sheet = Health::TrackingSheet.new(@patients)
          render(xlsx: 'index', filename: "Tracking Sheet #{date}.xlsx")
        end
      end
    end

    def patient_scope
      population = if current_user.can_administer_health?
        patient_source # Can see all clients
      elsif current_user.can_manage_care_coordinators? # Can see clients and those of team mates
        ids = [current_user.id] + current_user.team_mates.pluck(:id)
        patient_source.
          where(care_coordinator_id: ids).
          or(patient_source.where(nurse_care_manager_id: ids))
      else # Can see your own clients
        patient_source.
          where(care_coordinator_id: current_user.id).
          or(patient_source.where(nurse_care_manager_id: current_user.id))
      end

      population.
        # Assigned, and enrolled
        joins(:patient_referral).
        merge(Health::PatientReferral.assigned.not_disenrolled).
        or(
          # Have an un-confirmed MassHealth pending disenrollment
          population.
            joins(:patient_referral).
            merge(Health::PatientReferral.pending_disenrollment.not_confirmed_rejected),
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
