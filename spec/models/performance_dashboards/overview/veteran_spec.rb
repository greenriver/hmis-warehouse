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

  describe 'veteran_bucket' do
    it 'returns 99 for nil values' do
      expect(report.veteran_bucket(nil)).to eq(99)
    end

    it 'returns the veteran status value for valid values' do
      expect(report.veteran_bucket(0)).to eq(0)
      expect(report.veteran_bucket(1)).to eq(1)
      expect(report.veteran_bucket(8)).to eq(8)
      expect(report.veteran_bucket(9)).to eq(9)
      expect(report.veteran_bucket(99)).to eq(99)
    end
  end

  describe 'veteran_bucket_titles' do
    it 'returns a hash mapping veteran status keys to labels from HUD utility' do
      titles = report.veteran_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(HudHelper.util.no_yes_reasons_for_missing_data_options.keys)
      titles.each do |key, label|
        expect(label).to eq(HudHelper.util.veteran_status(key))
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe '#enrolled_by_veteran' do
    context 'with clients having different veteran statuses' do
      let!(:non_veteran_client) { create_client_with_field(:VeteranStatus, 0) }
      let!(:veteran_client) { create_client_with_field(:VeteranStatus, 1) }
      let!(:unknown_client) { create_client_with_field(:VeteranStatus, 8) }
      let!(:refused_client) { create_client_with_field(:VeteranStatus, 9) }
      let!(:not_collected_client) { create_client_with_field(:VeteranStatus, 99) }
      let!(:nil_client) { create_client_with_field(:VeteranStatus, nil) }

      before do
        [non_veteran_client, veteran_client, unknown_client, refused_client, not_collected_client, nil_client].each do |client|
          enrollment = create_enrollment(
            client: client,
            project: project,
            entry_date: start_date + 10.days,
          )
          create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        end
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by veteran status' do
        buckets = report.enrolled_by_veteran
        expect(buckets[0]).to include(non_veteran_client.warehouse_client_source.destination_id)
        expect(buckets[1]).to include(veteran_client.warehouse_client_source.destination_id)
        expect(buckets[8]).to include(unknown_client.warehouse_client_source.destination_id)
        expect(buckets[9]).to include(refused_client.warehouse_client_source.destination_id)
        expect(buckets[99]).to include(not_collected_client.warehouse_client_source.destination_id)
        expect(buckets[99]).to include(nil_client.warehouse_client_source.destination_id)
      end

      it 'maps nil values to 99 bucket' do
        buckets = report.enrolled_by_veteran
        expect(buckets[99]).to include(nil_client.warehouse_client_source.destination_id)
      end

      it 'returns correct counts for each bucket' do
        buckets = report.enrolled_by_veteran
        expect(buckets[0].count).to eq(1)
        expect(buckets[1].count).to eq(1)
        expect(buckets[8].count).to eq(1)
        expect(buckets[9].count).to eq(1)
        expect(buckets[99].count).to eq(2) # not_collected + nil
      end
    end
  end

  describe '#entering_by_veteran' do
    let!(:entering_client) do
      client = create_client_with_field(:VeteranStatus, 1)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    let!(:pre_existing_client) do
      client = create_client_with_field(:VeteranStatus, 0)
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
      buckets = report.entering_by_veteran
      expect(buckets[1]).to include(entering_client.warehouse_client_source.destination_id)
      expect(buckets[0]).not_to include(pre_existing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#exiting_by_veteran' do
    let!(:exiting_client) do
      client = create_client_with_field(:VeteranStatus, 1)
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
      client = create_client_with_field(:VeteranStatus, 0)
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
      buckets = report.exiting_by_veteran
      expect(buckets[1]).to include(exiting_client.warehouse_client_source.destination_id)
      expect(buckets[0]).not_to include(ongoing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#enrolled_by_veteran_data_for_chart' do
    let!(:client) do
      c = create_client_with_field(:VeteranStatus, 1)
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
      data = report.enrolled_by_veteran_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_veteran_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end
  end
end
