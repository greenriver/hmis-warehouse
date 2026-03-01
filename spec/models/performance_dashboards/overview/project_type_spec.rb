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
  let!(:es_project) { create_project(project_type: 1) } # ES project type
  let!(:th_project) { create_project(project_type: 2) } # TH project type
  let!(:report) { described_class.new(filter) }

  before do
    user.add_viewable(es_project)
    user.add_viewable(th_project)
  end

  describe 'project_type_bucket_titles' do
    it 'returns a hash mapping project type keys to labels from HUD utility' do
      titles = report.project_type_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(report.send(:project_type_buckets))
      titles.each do |key, label|
        expect(label).to eq(HudHelper.util.project_type(key))
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe 'project_type_bucket' do
    it 'returns the project type value' do
      expect(report.project_type_bucket(1)).to eq(1)
      expect(report.project_type_bucket(2)).to eq(2)
    end
  end

  describe '#enrolled_by_project_type' do
    context 'with clients in different project types' do
      let!(:es_client) do
        client = create_client_with_warehouse_link
        enrollment = create_enrollment(
          client: client,
          project: es_project,
          entry_date: start_date + 10.days,
        )
        create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        client
      end
      let!(:th_client) do
        client = create_client_with_warehouse_link
        enrollment = create_enrollment(
          client: client,
          project: th_project,
          entry_date: start_date + 10.days,
        )
        create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        client
      end

      before do
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by project type' do
        buckets = report.enrolled_by_project_type
        expect(buckets).to be_a(Hash)
        expect(buckets[1]).to include(es_client.warehouse_client_source.destination_id)
        expect(buckets[2]).to include(th_client.warehouse_client_source.destination_id)
      end
    end
  end

  describe '#enrolled_by_project_type_data_for_chart' do
    let!(:client) do
      c = create_client_with_warehouse_link
      enrollment = create_enrollment(
        client: c,
        project: es_project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      c
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'returns data with columns and categories' do
      data = report.enrolled_by_project_type_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_project_type_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end
  end
end
