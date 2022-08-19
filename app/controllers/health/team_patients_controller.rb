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

    def index
      @active_team = ::Health::CoordinationTeam.find_by(id: params[:entity_id])
      @active_team ||= ::Health::CoordinationTeam.find_by(team_coordinator_id: current_user.id) ||
        Health::UserCareCoordinator.find_by(user_id: current_user.id)&.coordination_team ||
        ::Health::CoordinationTeam.first

      @report = Health::TeamPerformance.new(range: (Date.today..Date.tomorrow), team_scope: Health::CoordinationTeam.all)
      @teams = @report.team_counts
      @totals = @report.total_counts
      @patients = Health::Patient.where(id: @report.team_counts.detect { |counts| counts.id == @active_team.id }.patient_referrals)
      medicaid_ids = @patients.map(&:medicaid_id)
      @scores = calculate_dashboards(medicaid_ids)

      @pagy, @patients = pagy(@patients)
    end

    def detail
      @team_id = params.require(:entity)[:entity_id]&.to_i
      @section = params.require(:entity)[:section]
      @patient_ids = params.require(:entity)[:patient_ids]&.split(',')&.map(&:to_i)
      @patients = Health::Patient.bh_cp.where(id: @patient_ids).
        preload(:care_coordinator).
        order(last_name: :asc, first_name: :asc)

      @team = Health::CoordinationTeam.find(@team_id)
    end
  end
end
