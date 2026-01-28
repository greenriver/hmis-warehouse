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

  describe 'age_bucket' do
    it 'returns :unknown for nil values' do
      expect(report.age_bucket(nil)).to eq(:unknown)
    end

    it 'returns correct bucket for various ages' do
      expect(report.age_bucket(17)).to eq(:under_eighteen)
      expect(report.age_bucket(20)).to eq(:eighteen_to_twenty_four)
      expect(report.age_bucket(27)).to eq(:twenty_five_to_twenty_nine)
      expect(report.age_bucket(35)).to eq(:thirty_to_thirty_nine)
      expect(report.age_bucket(45)).to eq(:forty_to_forty_nine)
      expect(report.age_bucket(52)).to eq(:fifty_to_fifty_four)
      expect(report.age_bucket(57)).to eq(:fifty_five_to_fifty_nine)
      expect(report.age_bucket(60)).to eq(:sixty_to_sixty_one)
      expect(report.age_bucket(65)).to eq(:over_sixty_one)
    end
  end

  describe 'age_bucket_titles' do
    it 'returns a hash mapping age bucket keys to labels' do
      titles = report.age_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(PerformanceDashboard::Overview::Age::AGE_BUCKET_TITLES.keys)
      titles.each do |key, label|
        expect(label).to eq(PerformanceDashboard::Overview::Age::AGE_BUCKET_TITLES[key])
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe '#enrolled_by_age' do
    context 'with clients having different ages' do
      let!(:child_client) { create_client_with_field(:DOB, start_date - 10.years) }
      let!(:young_adult_client) { create_client_with_field(:DOB, start_date - 22.years) }
      let!(:adult_client) { create_client_with_field(:DOB, start_date - 35.years) }

      before do
        [child_client, young_adult_client, adult_client].each do |client|
          enrollment = create_enrollment(
            client: client,
            project: project,
            entry_date: start_date + 10.days,
          )
          create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        end
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by age bucket' do
        buckets = report.enrolled_by_age
        expect(buckets[:under_eighteen]).to include(child_client.warehouse_client_source.destination_id)
        expect(buckets[:eighteen_to_twenty_four]).to include(young_adult_client.warehouse_client_source.destination_id)
        expect(buckets[:thirty_to_thirty_nine]).to include(adult_client.warehouse_client_source.destination_id)
      end

      it 'returns correct counts for each bucket' do
        buckets = report.enrolled_by_age
        expect(buckets[:under_eighteen].count).to eq(1)
        expect(buckets[:eighteen_to_twenty_four].count).to eq(1)
        expect(buckets[:thirty_to_thirty_nine].count).to eq(1)
      end
    end
  end

  describe '#entering_by_age' do
    let!(:entering_client) do
      client = create_client_with_field(:DOB, start_date - 25.years)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    let!(:pre_existing_client) do
      client = create_client_with_field(:DOB, start_date - 30.years)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date - 30.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date - 30.days)
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'only includes clients entering in the date range' do
      buckets = report.entering_by_age
      expect(buckets[:twenty_five_to_twenty_nine]).to include(entering_client.warehouse_client_source.destination_id)
      expect(buckets[:thirty_to_thirty_nine]).not_to include(pre_existing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#exiting_by_age' do
    let!(:exiting_client) do
      client = create_client_with_field(:DOB, start_date - 28.years)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date - 30.days,
        exit_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 5.days)
      client
    end

    let!(:ongoing_client) do
      client = create_client_with_field(:DOB, start_date - 32.years)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date - 30.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'only includes clients exiting in the date range' do
      buckets = report.exiting_by_age
      expect(buckets[:twenty_five_to_twenty_nine]).to include(exiting_client.warehouse_client_source.destination_id)
      expect(buckets[:thirty_to_thirty_nine]).not_to include(ongoing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#enrolled_by_age_data_for_chart' do
    let!(:client) do
      c = create_client_with_field(:DOB, start_date - 20.years)
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
      data = report.enrolled_by_age_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_age_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end
  end
end
