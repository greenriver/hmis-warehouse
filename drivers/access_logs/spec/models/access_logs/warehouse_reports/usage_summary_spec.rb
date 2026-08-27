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

  after { GrdaWarehouse::Config.invalidate_cache }
  before { Rails.cache.clear }

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

  # created_at is a timestamp column. Both bounds of the Date range must expand to whole
  # local days, or same-day activity logged after midnight UTC (evening Eastern) is dropped
  # and pre-range activity logged after midnight UTC is counted.
  it 'counts a visit logged on the last day of the range after midnight UTC' do
    travel_to Time.zone.local(2026, 8, 31, 22, 15) do
      log_visit(user: user_1, path: chronic_path, visited_at: Time.current)

      report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

      expect(report&.dig(:user_visits, user_1.id.to_s)).to eq(1)
    end
  end

  it 'excludes a visit from the day before the range starts even when it falls after midnight UTC' do
    log_visit(user: user_1, path: chronic_path, visited_at: range.begin.beginning_of_day + 21.hours)
    log_visit(user: user_1, path: chronic_path, visited_at: range.begin.beginning_of_day - 3.hours)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:user_visits][user_1.id.to_s]).to eq(1)
  end

  # visit days are counted per local calendar day, so a day boundary in UTC must not split or
  # merge a user's visits.
  it 'counts two same-day Eastern visits that straddle midnight UTC as one visit day' do
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago.beginning_of_day + 19.hours)
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago.beginning_of_day + 21.hours)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:user_visits][user_1.id.to_s]).to eq(1)
    expect(report[:unique_visits]).to eq(1)
  end

  it 'counts an 11pm visit and a 1am visit on consecutive Eastern days as two visit days' do
    log_visit(user: user_1, path: chronic_path, visited_at: 2.days.ago.beginning_of_day + 23.hours)
    log_visit(user: user_1, path: chronic_path, visited_at: 1.day.ago.beginning_of_day + 1.hour)

    report = summary[:reports].find { |r| r[:key] == 'warehouse_reports/chronic' }

    expect(report[:user_visits][user_1.id.to_s]).to eq(2)
  end

  # Nightly Census's sub-routes (/censuses/date_range, /censuses/details) are also used by an
  # AJAX widget embedded on the project show page (app/views/projects/show.haml), so path alone
  # can't tell "visited the report" from "opened a project page that happens to embed its chart."
  # ReportDefinition's `reporting_query` lets this one report require a Census-page referrer for
  # those sub-routes, while still always counting a bare /censuses visit.
  describe "Nightly Census's referrer-scoped reporting_query" do
    def log_referred_visit(user:, path:, referrer:, visited_at:)
      ActivityLog.create!(user: user, path: path, referrer: referrer, controller_name: 'censuses', action_name: 'date_range', ip_address: '127.0.0.1', created_at: visited_at)
    end

    it 'counts a bare visit to the report index regardless of referrer' do
      log_referred_visit(user: user_1, path: '/censuses', referrer: nil, visited_at: 1.day.ago)

      report = summary[:reports].find { |r| r[:key] == 'censuses' }

      expect(report[:unique_visits]).to eq(1)
    end

    it 'counts a date_range sub-request referred from the report itself' do
      log_referred_visit(user: user_1, path: '/censuses/date_range', referrer: 'https://hmis-warehouse.dev.test/censuses', visited_at: 1.day.ago)

      report = summary[:reports].find { |r| r[:key] == 'censuses' }

      expect(report[:unique_visits]).to eq(1)
    end

    it 'excludes a date_range sub-request referred from a project page (the embedded widget, not the report)' do
      log_referred_visit(user: user_1, path: '/censuses/date_range', referrer: 'https://hmis-warehouse.dev.test/projects/42', visited_at: 1.day.ago)

      expect(summary[:reports].map { |r| r[:key] }).not_to include('censuses')
    end
  end
end
