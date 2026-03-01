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

  describe 'gender_bucket' do
    it 'returns 99 for nil values' do
      expect(report.gender_bucket(nil)).to eq(99)
    end

    it 'returns the gender value for valid values' do
      expect(report.gender_bucket(0)).to eq(0)
      expect(report.gender_bucket(1)).to eq(1)
      expect(report.gender_bucket(2)).to eq(2)
      expect(report.gender_bucket(4)).to eq(4)
      expect(report.gender_bucket(5)).to eq(5)
      expect(report.gender_bucket(6)).to eq(6)
      expect(report.gender_bucket(8)).to eq(8)
      expect(report.gender_bucket(9)).to eq(9)
      expect(report.gender_bucket(99)).to eq(99)
    end
  end

  describe 'gender_bucket_titles' do
    it 'returns a hash mapping gender keys to labels from HUD utility' do
      titles = report.gender_bucket_titles
      expect(titles).to be_a(Hash)
      expect(titles.keys).to match_array(HudHelper.util.genders.keys)
      titles.each do |key, label|
        expect(label).to eq(HudHelper.util.gender(key))
        expect(label).to be_a(String)
        expect(label).to be_present
      end
    end
  end

  describe '#enrolled_by_gender' do
    context 'with clients having different gender values' do
      let!(:woman_client) { create_client_with_gender_fields(Woman: 1) }
      let!(:man_client) { create_client_with_gender_fields(Man: 1) }
      let!(:non_binary_client) { create_client_with_gender_fields(NonBinary: 1) }
      let!(:multiple_gender_client) { create_client_with_gender_fields(Woman: 1, Man: 1) }
      let!(:unknown_client) { create_client_with_gender_fields({}, GenderNone: 8) }
      let!(:refused_client) { create_client_with_gender_fields({}, GenderNone: 9) }
      let!(:not_collected_client) { create_client_with_gender_fields({}, GenderNone: 99) }
      let!(:nil_client) { create_client_with_gender_fields({}, GenderNone: nil) }

      before do
        [woman_client, man_client, non_binary_client, multiple_gender_client, unknown_client, refused_client, not_collected_client, nil_client].each do |client|
          enrollment = create_enrollment(
            client: client,
            project: project,
            entry_date: start_date + 10.days,
          )
          create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
        end
        rebuild_service_history_and_clear_cache
      end

      it 'groups clients by gender value' do
        buckets = report.enrolled_by_gender
        expect(buckets[0]).to include(woman_client.warehouse_client_source.destination_id)
        expect(buckets[1]).to include(man_client.warehouse_client_source.destination_id)
        expect(buckets[4]).to include(non_binary_client.warehouse_client_source.destination_id)
        expect(buckets[8]).to include(unknown_client.warehouse_client_source.destination_id)
        expect(buckets[9]).to include(refused_client.warehouse_client_source.destination_id)
        expect(buckets[99]).to include(not_collected_client.warehouse_client_source.destination_id)
        expect(buckets[99]).to include(nil_client.warehouse_client_source.destination_id)
      end

      it 'maps empty gender data to 99 bucket' do
        buckets = report.enrolled_by_gender
        expect(buckets[99]).to include(nil_client.warehouse_client_source.destination_id)
      end

      it 'handles clients with multiple genders' do
        buckets = report.enrolled_by_gender
        # Client with both Woman and Man should appear in both buckets
        expect(buckets[0]).to include(multiple_gender_client.warehouse_client_source.destination_id)
        expect(buckets[1]).to include(multiple_gender_client.warehouse_client_source.destination_id)
      end

      it 'returns correct counts for each bucket' do
        buckets = report.enrolled_by_gender
        expect(buckets[0].count).to eq(2) # woman_client + multiple_gender_client
        expect(buckets[1].count).to eq(2) # man_client + multiple_gender_client
        expect(buckets[4].count).to eq(1) # non_binary_client
        expect(buckets[8].count).to eq(1) # unknown_client
        expect(buckets[9].count).to eq(1) # refused_client
        expect(buckets[99].count).to eq(2) # not_collected + nil
      end
    end

    context 'with multiple enrollments for same client' do
      let!(:client) do
        c = create_client_with_warehouse_link
        set_client_gender_fields(c, Woman: 1)
        c
      end

      before do
        # Create two enrollments, most recent should win
        enrollment1 = create_enrollment(
          client: client,
          project: project,
          entry_date: start_date + 5.days,
        )
        create_bed_night_service(enrollment: enrollment1, date: start_date + 5.days)

        enrollment2 = create_enrollment(
          client: client,
          project: project,
          entry_date: start_date + 10.days,
        )
        create_bed_night_service(enrollment: enrollment2, date: start_date + 10.days)

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      end

      it 'counts each client only once per gender bucket' do
        buckets = report.enrolled_by_gender
        expect(buckets[0].count).to eq(1)
        expect(buckets[0]).to include(client.warehouse_client_source.destination_id)
      end
    end
  end

  describe '#entering_by_gender' do
    let!(:entering_client) do
      client = create_client_with_gender_fields(Woman: 1)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    let!(:pre_existing_client) do
      client = create_client_with_gender_fields(Man: 1)
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
      buckets = report.entering_by_gender
      expect(buckets[0]).to include(entering_client.warehouse_client_source.destination_id)
      expect(buckets[1]).not_to include(pre_existing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#exiting_by_gender' do
    let!(:exiting_client) do
      client = create_client_with_gender_fields(Woman: 1)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date - 30.days,
        exit_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date - 10.days)
      create_bed_night_service(enrollment: enrollment, date: start_date + 5.days)
      client
    end

    let!(:ongoing_client) do
      client = create_client_with_gender_fields(Man: 1)
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
      buckets = report.exiting_by_gender
      expect(buckets[0]).to include(exiting_client.warehouse_client_source.destination_id)
      expect(buckets[1]).not_to include(ongoing_client.warehouse_client_source.destination_id)
    end
  end

  describe '#enrolled_by_gender_data_for_chart' do
    let!(:woman_client) do
      client = create_client_with_gender_fields(Woman: 1)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    let!(:man_client) do
      client = create_client_with_gender_fields(Man: 1)
      enrollment = create_enrollment(
        client: client,
        project: project,
        entry_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 10.days)
      client
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'returns data with columns and categories' do
      data = report.enrolled_by_gender_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
      expect(data[:columns]).to be_an(Array)
      expect(data[:categories]).to be_an(Array)
    end

    it 'includes date range words as first column' do
      data = report.enrolled_by_gender_data_for_chart
      expect(data[:columns].first).to eq(filter.date_range_words)
    end

    it 'includes counts for each gender bucket' do
      data = report.enrolled_by_gender_data_for_chart
      # Should have date + counts for each bucket
      expect(data[:columns].length).to be > 1
    end

    it 'includes categories matching gender bucket keys' do
      data = report.enrolled_by_gender_data_for_chart
      # Categories are the bucket keys (0, 1, etc.), not the labels
      expect(data[:categories]).to be_an(Array)
      expect(data[:categories].length).to be > 0
    end
  end

  describe '#entering_by_gender_data_for_chart' do
    let!(:client) do
      c = create_client_with_warehouse_link
      set_client_gender_fields(c, Woman: 1)
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

    it 'returns formatted chart data' do
      data = report.entering_by_gender_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
    end
  end

  describe '#exiting_by_gender_data_for_chart' do
    let!(:client) do
      c = create_client_with_warehouse_link
      set_client_gender_fields(c, Woman: 1)
      enrollment = create_enrollment(
        client: c,
        project: project,
        entry_date: start_date - 30.days,
        exit_date: start_date + 10.days,
      )
      create_bed_night_service(enrollment: enrollment, date: start_date + 5.days)
      c
    end

    before do
      rebuild_service_history_and_clear_cache
    end

    it 'returns formatted chart data' do
      data = report.exiting_by_gender_data_for_chart
      expect(data).to have_key(:columns)
      expect(data).to have_key(:categories)
    end
  end
end
