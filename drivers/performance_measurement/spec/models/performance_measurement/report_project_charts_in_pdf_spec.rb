###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::Report, '#project_charts_in_pdf?', type: :model do
  before { PerformanceMeasurement::Goal.ensure_default }

  let(:user) { create(:user) }

  def build_report
    PerformanceMeasurement::Report.create!(user_id: user.id, goal_configuration: PerformanceMeasurement::Goal.default_goal)
  end

  def add_projects(report, count)
    PerformanceMeasurement::Project.import!(
      [:report_id, :project_id],
      (1..count).map { |i| [report.id, i] },
    )
  end

  it 'keeps project charts at exactly the limit' do
    report = build_report
    add_projects(report, 200)

    expect(report.project_charts_in_pdf?).to eq(true)
  end

  it 'leaves project charts out one project over the limit' do
    report = build_report
    add_projects(report, 201)

    expect(report.project_charts_in_pdf?).to eq(false)
  end

  it "counts only this report's projects" do
    report = build_report
    add_projects(report, 1)
    add_projects(build_report, 201)

    expect(report.project_charts_in_pdf?).to eq(true)
  end
end
