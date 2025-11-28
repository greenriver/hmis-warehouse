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
    [
      create_project(project_type: 0),
      create_project(project_type: 1),
      create_project(project_type: 2),
      create_project(project_type: 3),
      create_project(project_type: 8),
    ]
  end

  let(:household_count) { 35 }
  let(:members_per_household) { 3 }
  let(:enrollments_per_member) { 10 }
  let(:expected_enrollment_count) { household_count * members_per_household * enrollments_per_member }
  let(:create_bed_nights) { false }

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
    bulk_build_households(
      projects: projects,
      base_entry_date: default_filter.start,
      household_count: household_count,
      members_per_household: members_per_household,
      enrollments_per_member: enrollments_per_member,
      create_bed_nights: create_bed_nights,
    )
    ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: GrdaWarehouse::Tasks::ServiceHistory::Enrollment.pluck(:id)).perform
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    raise "expected all enrollments to be processed" unless GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.count.zero?

    report
  end
end

RSpec.shared_context 'SPM measure configs', shared_context: :metadata do
  # Individual measure configurations
  # Override these in specific test contexts as needed
  let(:measure_one_config) { { query_count: 225..255, timing_secs: 10, debug: true } }
  let(:measure_two_config) { { query_count: 375..425, timing_secs: 10 } }
  let(:measure_three_config) { { query_count: 125..165, timing_secs: 10 } }
  let(:measure_four_config) { { query_count: 195..245, timing_secs: 10 } }
  let(:measure_five_config) { { query_count: 140..180, timing_secs: 15 } }
  let(:measure_six_config) { { query_count: 15..65, timing_secs: 10 } }
  let(:measure_seven_config) { { query_count: 245..265, timing_secs: 10 } }
  let(:hdx_upload_config) { { query_count: 1535..1560, timing_secs: 10 } }

  let(:enrollment_set_query_count) { 40..60 }
  let(:enrollment_set_timing_secs) { 10 }

  let(:all_measure_classes) do
    [
      HudSpmReport::Generators::Fy2026::MeasureOne,
      HudSpmReport::Generators::Fy2026::MeasureTwo,
      HudSpmReport::Generators::Fy2026::MeasureThree,
      HudSpmReport::Generators::Fy2026::MeasureFour,
      HudSpmReport::Generators::Fy2026::MeasureFive,
      HudSpmReport::Generators::Fy2026::MeasureSix,
      HudSpmReport::Generators::Fy2026::MeasureSeven,
      HudSpmReport::Generators::Fy2026::HdxUpload,
    ]
  end

  let(:question_names) { all_measure_classes.map(&:question_number) }
end

RSpec.shared_examples 'SPM performance budget validation' do
  # Helper to assert performance for a specific measure
  # Makes it explicit which measure is being tested and simplifies failure diagnosis
  def assert_performance(measure_name:, measure_config:)
    measure_class = "HudSpmReport::Generators::Fy2026::#{measure_name}".constantize
    return unless measure_class

    query_count = measure_config[:query_count]
    timing_secs = measure_config[:timing_secs]
    debug = measure_config[:debug] || false

    expect do
      puts "start run_measure #{measure_class.name} at #{Time.current.strftime("%H:%M:%S")}" if debug
      prior_level = Rails.logger.level
      Rails.logger.level = 0 if debug
      run_measure(report, measure_class)
      Rails.logger.level = prior_level
    end.to(
      make_database_queries(count: query_count).
        and(perform_under(timing_secs).secs.sample(1).times.warmup(0))
    )

    expect(report.report_cells.where(question: measure_class.question_number)).to exist
  end

  it 'limits queries for enrollment creation and each measure run' do
    aggregate_failures do
      expect do
        HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
      end.to(
        make_database_queries(count: enrollment_set_query_count).
          and(perform_under(enrollment_set_timing_secs).secs.sample(1).times.warmup(0)),
      )

      expect(report.spm_enrollments.count).to eq(expected_enrollment_count)

      assert_performance(measure_name: 'MeasureOne', measure_config: measure_one_config)
      assert_performance(measure_name: 'MeasureTwo', measure_config: measure_two_config)
      assert_performance(measure_name: 'MeasureThree', measure_config: measure_three_config)
      assert_performance(measure_name: 'MeasureFour', measure_config: measure_four_config)
      assert_performance(measure_name: 'MeasureFive', measure_config: measure_five_config)
      assert_performance(measure_name: 'MeasureSix', measure_config: measure_six_config)
      assert_performance(measure_name: 'MeasureSeven', measure_config: measure_seven_config)
      assert_performance(measure_name: 'HdxUpload', measure_config: hdx_upload_config)
    end
  end
end

RSpec.describe 'FY2026 SPM performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  include_examples 'SPM performance budget validation'
end

RSpec.describe 'FY2026 SPM performance budget with large dataset', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  # Increase data size significantly to test multiple batches
  # enrollment_batches uses in_batches which defaults to 1000 records per batch
  # ~1,050 enrollments = 1-2 batches, ~5,000 enrollments = 5+ batches
  # This test verifies that query counts remain constant (or scale sub-linearly) with data size,
  # confirming that batching is working properly and we're not doing N+1 queries
  let(:household_count) { 167 } # 167 * 3 * 10 = 5,010 enrollments
  let(:enrollment_set_query_count) { 90..120 }
  let(:enrollment_set_timing_secs) { 30 }

  # Allow more time for larger dataset
  #let(:measure_one_config) { { query_count: 245..195, timing_secs: 15 } }
  #let(:measure_two_config) { { query_count: 400..450, timing_secs: 15 } }
  #let(:measure_three_config) { { query_count: 85..135, timing_secs: 15 } }
  #let(:measure_four_config) { { query_count: 195..245, timing_secs: 15 } }
  #let(:measure_five_config) { { query_count: 120..160, timing_secs: 15,  } }
  #let(:measure_six_config) { { query_count: 15..65, timing_secs: 15 } }
  #let(:measure_seven_config) { { query_count: 110..150, timing_secs: 15 } }
  #let(:hdx_upload_config) { { query_count: 605..655, timing_secs: 15 } }



  include_examples 'SPM performance budget validation'
end

RSpec.describe 'FY2026 SPM performance budget with services', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:create_bed_nights) { true }

  # Only test MeasureOne with service queries
  let(:measure_one_config) { { query_count: 215..265, timing_secs: 15 } }
  let(:question_names) { [HudSpmReport::Generators::Fy2026::MeasureOne.question_number] }

  include_examples 'SPM performance budget validation'
end
