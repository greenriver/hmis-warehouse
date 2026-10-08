###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::DocumentExports::ScorecardExport, type: :model do
  include_context 'report visibility users'

  let(:report_class) { BostonProjectScorecard::Report }
  let(:report_definition_url) { 'boston_project_scorecard/warehouse_reports/scorecards' }
  let(:report_attributes) { { start_date: 1.year.ago.to_date, end_date: Date.current } }

  def export_for(user, report_id)
    described_class.new(user: user, query_string: { report_id: report_id }.to_query)
  end

  # Scorecards are shared: project contacts respond to scorecards they did not create.
  it 'authorizes a scorecard another user created when the scorecard report is assigned' do
    expect(export_for(own_reports_user, others_report.id).authorized?).to be(true)
  end

  it 'refuses a user without the scorecard report assigned' do
    user = create(:acl_user)
    setup_access_control(user, create(:role, name: 'unassigned all reports', can_view_all_reports: true, can_view_assigned_reports: true), create(:collection))

    expect(export_for(user, own_report.id).authorized?).to be(false)
  end

  it 'refuses a user with the scorecard report assigned but no report permission' do
    expect(export_for(user_with_role(can_view_clients: true), own_report.id).authorized?).to be(false)
  end

  it 'refuses an id with no scorecard' do
    expect(export_for(all_reports_user, 0).authorized?).to be(false)
  end
end
