###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::HealthTeamPatientsTableJob < BackgroundRenderJob
  def render_html(user_id:, start_date:, end_date:)
    current_user = User.find(user_id)

    report = Health::TeamPerformance.new(range: (Date.parse(start_date)..Date.parse(end_date)), team_scope: Health::CoordinationTeam.all)
    teams = report.team_counts
    totals = report.total_counts

    Health::TeamPatientsController.render(
      partial: 'warehouse_reports/health/agency_performance/table',
      locals: {
        report: report,
        entities: teams,
        entity_label: 'Team',
        totals: totals,
        detail_path: [:detail, :health, :team_patients],
        permission: current_user.has_some_patient_access?,
        current_user: current_user,
      },
    )
  end
end
