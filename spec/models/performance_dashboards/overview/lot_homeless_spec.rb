###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../shared_contexts/hud_enrollment_builders'
require_relative '../../../shared_contexts/performance_dashboard_helpers'

RSpec.describe PerformanceDashboards::Overview, type: :model do
  include_context 'HUD enrollment builders'
  include_context 'performance dashboard helpers'

  let(:start_date) { Date.parse('2024-01-01') }
  let(:end_date) { Date.parse('2024-12-31') }
  let(:filter) do
    Filters::PerformanceDashboard.new(
      user: user,
      start: start_date,
      end: end_date,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
      sub_population: :clients,
      enforce_one_year_range: false,
      require_service_during_range: true,
    )
  end
  let!(:project) { create_project(project_type: 1) } # ES project type
  let!(:report) { described_class.new(filter) }

  before do
    user.add_viewable(project)
  end

  describe 'lot_homeless_bucket' do
    it 'returns :unknown for nil values' do
      expect(report.lot_homeless_bucket(nil)).to eq(:unknown)
    end

    it 'returns correct bucket for various lengths of time' do
      expect(report.lot_homeless_bucket(5)).to eq(:one_week)
      expect(report.lot_homeless_bucket(15)).to eq(:one_week_to_one_month)
      expect(report.lot_homeless_bucket(45)).to eq(:one_to_two_months)
      expect(report.lot_homeless_bucket(75)).to eq(:two_to_three_months)
      expect(report.lot_homeless_bucket(120)).to eq(:three_to_six_months)
      expect(report.lot_homeless_bucket(200)).to eq(:six_months_to_one_year)
      expect(report.lot_homeless_bucket(500)).to eq(:one_to_two_years)
      expect(report.lot_homeless_bucket(800)).to eq(:over_two_years)
    end
  end

  describe 'lot_homeless_bucket_titles' do
    it 'returns a hash mapping LOT homeless bucket keys to labels' do
      titles = report.lot_homeless_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(PerformanceDashboard::Overview::LotHomeless::LOT_HOMELESS_BUCKET_TITLES.keys)
      titles.each do |key, label|
        expect(label).to eq(PerformanceDashboard::Overview::LotHomeless::LOT_HOMELESS_BUCKET_TITLES[key])
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe '#enrolled_by_lot_homeless' do
    context 'with clients having different lengths of time homeless' do
      let!(:short_term_client) do
        client = create_client_with_warehouse_link
        create(
          :grda_warehouse_warehouse_clients_processed,
          client: client.warehouse_client_source.destination,
          days_homeless_last_three_years: 5,
        )
        client
      end
      let!(:long_term_client) do
        client = create_client_with_warehouse_link
        create(
          :grda_warehouse_warehouse_clients_processed,
          client: client.warehouse_client_source.destination,
          days_homeless_last_three_years: 500,
        )
        client
      end

      before do
        [short_term_client, long_term_client].each do |client|
          enrollment = create_enrollment(
            client: client,
            project: project,
            entry_date: start_date + 10.days,
          )
          create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        end
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by length of time homeless bucket' do
        buckets = report.enrolled_by_lot_homeless
        expect(buckets).to be_a(Hash)
        expect(buckets.keys).to include(:one_week, :one_to_two_years, :unknown)
      end
    end
  end

  describe '#enrolled_by_lot_homeless_data_for_chart' do
    let!(:client) do
      c = create_client_with_warehouse_link
      create(
        :grda_warehouse_warehouse_clients_processed,
        client: c.warehouse_client_source.destination,
        days_homeless_last_three_years: 100,
      )
      enrollment = create_enrollment(
        client: c,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      c
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'returns data with columns and categories' do
      data = report.enrolled_by_lot_homeless_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_lot_homeless_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end
  end
end
