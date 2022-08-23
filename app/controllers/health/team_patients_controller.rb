###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class TeamPatientsController < HealthController
    include ClientPathGenerator
    include AjaxModalRails::Controller
    include HealthPatientDashboard

    before_action :require_can_view_patients_for_own_agency!
    before_action :set_dates

    def index
      @team_name = if params[:entity_id].present?
        @active_team = ::Health::CoordinationTeam.find_by(name: params[:entity_id])
        @active_team ||= ::Health::CoordinationTeam.find_by(team_coordinator_id: current_user.id) ||
          Health::UserCareCoordinator.find_by(user_id: current_user.id)&.coordination_team ||
          ::Health::CoordinationTeam.first
        @active_team.name
      else
        'All Patients'
      end

      @report = Health::TeamPerformance.new(range: (@start_date..@end_date), team_scope: Health::CoordinationTeam.all)
      @teams = @report.team_counts
      @totals = @report.total_counts

      @patients = if params[:entity_id].present?
        patient_source.where(id: @report.team_counts.detect { |counts| counts.name == @active_team&.name }.patient_referrals)
      else
        patient_source.where(id: @report.total_counts.patient_referrals)
      end

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

    def detail
      team_name = params.require(:entity)[:entity_id]
      @section = params.require(:entity)[:section]
      @patient_ids = params.require(:entity)[:patient_ids]&.split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        preload(:care_coordinator).
        order(last_name: :asc, first_name: :asc)

      @team = Health::CoordinationTeam.find_by(name: team_name)
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

    private def patient_source
      Health::Patient
    end
  end
end
