###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessLogs::WarehouseReports::UsageSummary do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:range) { 10.days.ago.to_date..Date.current }

  # Real ReportDefinition.report_list entries -- this service reads that list directly, not a factory.
  let(:chronic_path) { '/warehouse_reports/chronic/1234' }
  let(:hud_chronic_path) { '/warehouse_reports/hud_chronics/5678' }

  def log_visit(user:, path:, visited_at:)
    ActivityLog.create!(user: user, path: path, controller_name: 'warehouse_reports', action_name: 'show', ip_address: '127.0.0.1', created_at: visited_at)
  end

  subject(:summary) { described_class.new(range: range).call }

  it "counts a user's distinct calendar days per report, deduping same-day visits" do
    log_visit(user: user_1, path: chronic_path, visited_at: 2.days.ago.beginning_of_day + 9.hours)
    log_visit(user: user_1, path: chronic_path, visited_at: 2.days.ago.beginning_of_day + 15.hours)
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago.beginning_of_day + 9.hours)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:user_visits][user_1.id.to_s]).to eq(2)
    expect(report[:unique_visits]).to eq(2)
  end

  it 'buckets activity under the correct report by path prefix' do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago)
    log_visit(user: user_2, path: hud_chronic_path, visited_at: 1.day.ago)

    chronic = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }
    hud_chronic = summary[:reports].find { |r| r[:key] == 'warehouse_reports/hud_chronics' }

    expect(chronic[:user_visits].keys).to contain_exactly(user_1.id.to_s)
    expect(hud_chronic[:user_visits].keys).to contain_exactly(user_2.id.to_s)
  end

  it 'excludes activity from before the given date range' do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago)
    log_visit(user: user_1, path: chronic_path, visited_at: range.begin - 1.day)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:user_visits][user_1.id.to_s]).to eq(1)
  end

  it "excludes activity whose path doesn't match any report" do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago)
    log_visit(user: user_1, path: '/not_a_report/whatever', visited_at: 1.day.ago)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:unique_visits]).to eq(1)
    expect(summary[:reports].map { |r| r[:key] }).not_to include('not_a_report/whatever')
  end

  it "sums a user's visits across multiple reports into user_totals" do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago)
    log_visit(user: user_1, path: hud_chronic_path, visited_at: 1.day.ago)
    log_visit(user: user_1, path: hud_chronic_path, visited_at: 2.days.ago)

    expect(summary[:user_totals][user_1.id.to_s]).to eq(3)
  end

  it 'omits reports with no activity in range from the output' do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago)

    expect(summary[:reports].map { |r| r[:key] }).to eq(['warehouse_reports/chronic'])
  end
end
