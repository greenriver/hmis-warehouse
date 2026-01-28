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

  describe 'ethnicity_bucket_titles' do
    it 'returns a hash mapping ethnicity keys to labels from HUD utility' do
      titles = report.ethnicity_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(HudHelper.util.ethnicities.keys)
      titles.each do |key, label|
        expect(label).to eq(HudHelper.util.ethnicity(key))
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe '#enrolled_by_ethnicity' do
    context 'with clients having different ethnicity values' do
      let!(:hispanic_client) { create_client_with_race_fields({}, HispanicLatinaeo: 1) }
      let!(:non_hispanic_client) { create_client_with_race_fields({}, HispanicLatinaeo: 0) }

      before do
        [hispanic_client, non_hispanic_client].each do |client|
          enrollment = create_enrollment(
            client: client,
            project: project,
            entry_date: start_date + 10.days,
          )
          create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        end
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by ethnicity' do
        buckets = report.enrolled_by_ethnicity
        expect(buckets).to be_a(Hash)
        expect(buckets[:hispanic_latinaeo]).to include(hispanic_client.warehouse_client_source.destination_id)
        expect(buckets[:non_hispanic_latinaeo]).to include(non_hispanic_client.warehouse_client_source.destination_id)
      end
    end
  end

  describe '#enrolled_by_ethnicity_data_for_chart' do
    let!(:client) do
      c = create_client_with_race_fields({}, HispanicLatinaeo: 1)
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
      data = report.enrolled_by_ethnicity_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_ethnicity_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end
  end
end
