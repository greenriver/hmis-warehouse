###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::Report, type: :model do
  include_context 'report visibility users'

  let(:report_class) { described_class }
  let(:report_definition_url) { 'boston_project_scorecard/warehouse_reports/scorecards' }
  let(:report_attributes) { { start_date: 1.year.ago.to_date, end_date: Date.current } }

  let!(:reviewer_report) { described_class.create!(user_id: all_reports_user.id, secondary_reviewer_id: own_reports_user.id, **report_attributes) }
  let!(:other_reviewer_report) { described_class.create!(user_id: all_reports_user.id, secondary_reviewer_id: all_reports_user.id, **report_attributes) }

  it 'returns created and secondary-reviewer scorecards to a user who can view assigned reports' do
    expect(described_class.viewable_by(own_reports_user)).to contain_exactly(own_report, reviewer_report)
  end

  it 'returns every scorecard to a user who can view all reports' do
    expect(described_class.viewable_by(all_reports_user)).to contain_exactly(own_report, others_report, reviewer_report, other_reviewer_report)
  end

  it 'returns nothing to a secondary reviewer without a report permission' do
    user = user_with_role(can_view_clients: true)
    described_class.create!(user_id: user.id, secondary_reviewer_id: user.id, **report_attributes)

    expect(described_class.viewable_by(user)).to be_empty
  end
end
