###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.shared_context 'SPM performance dataset', shared_context: :metadata do
  include_context 'SPM test setup'

  let(:projects) do
    5.times.map { create_project(project_type: 1) }
  end

  let(:household_count) { 35 }
  let(:members_per_household) { 3 }
  let(:enrollments_per_member) { 10 }
  let(:query_range) { (query_count - 25)...(query_count + 25) }
  let(:expected_enrollment_count) { household_count * members_per_household * enrollments_per_member }

  let(:report) do
    filter = default_filter.dup
    filter.update(project_ids: projects.map(&:id))

    HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2026',
      build_for_questions: question_names,
    ).tap do |instance|
      instance.question_names = question_names
      instance.save!
    end
  end

  before do
    build_performance_households
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    report
  end

  def build_performance_households
    base_entry_date = default_filter.start

    household_count.times do |household_index|
      household_id = SecureRandom.uuid
      members_per_household.times do |member_index|
        client = create_client_with_warehouse_link
        relationship = member_index.zero? ? 1 : 2

        enrollments_per_member.times do |enrollment_index|
          project = projects[(household_index + enrollment_index) % projects.length]
          entry_date = base_entry_date + enrollment_index.days
          exit_date = entry_date + 1.day

          create_enrollment(
            client: client,
            project: project,
            entry_date: entry_date,
            exit_date: exit_date,
            relationship_to_ho_h: relationship,
            household_id: household_id,
            date_to_street_essh: entry_date - 30.days,
            living_situation: 100,
            destination: 301,
            move_in_date: relationship == 1 ? entry_date : nil,
          )
        end
      end
    end
  end
end

RSpec.describe 'FY2026 SPM performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:enrollment_set_query_count) { 75 }
  let(:enrollment_set_timing_secs) { 10 }
  let(:measure_configs) do
    [
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureOne,
        query_count: 170,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureTwo,
        query_count: 400,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureThree,
        query_count: 150,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureFour,
        query_count: 220,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureFive,
        query_count: 360,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureSix,
        query_count: 530,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::MeasureSeven,
        query_count: 250,
        timing_secs: 10,
      },
      {
        klass: HudSpmReport::Generators::Fy2026::HdxUpload,
        query_count: 580,
        timing_secs: 10,
      },
    ]
  end
  let(:question_names) { measure_configs.map { |config| config[:klass].question_number } }

  it 'limits queries for enrollment creation and each measure run' do
    aggregate_failures('spm enrollment creation') do
      expect do
        HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
      end.to(
        make_database_queries(count: (enrollment_set_query_count - 25)...(enrollment_set_query_count + 25)).
          and(perform_under(enrollment_set_timing_secs).secs.sample(1).times.warmup(0)),
        'SpmEnrollment.create_enrollment_set query budget',
      )
    end

    expect(report.spm_enrollments.count).to eq(expected_enrollment_count)

    measure_configs.each do |config|
      klass = config[:klass]
      query_count = config[:query_count]
      timing_secs = config[:timing_secs]
      query_budget = (query_count - 25)...(query_count + 25)

      # puts klass.name
      aggregate_failures(klass.name) do
        expect do
          run_measure(report, klass)
        end.to(
          make_database_queries(count: query_budget).
            and(perform_under(timing_secs).secs.sample(1).times.warmup(0)),
        )

        expect(report.report_cells.where(question: klass.question_number)).to exist
      end
    end
  end
end
