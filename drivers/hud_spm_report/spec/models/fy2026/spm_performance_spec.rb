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
  let(:measure_one_config) { { query_count: 145..195, timing_secs: 10 } }
  let(:measure_two_config) { { query_count: 375..425, timing_secs: 10 } }
  let(:measure_three_config) { { query_count: 85..135, timing_secs: 10 } }
  let(:measure_four_config) { { query_count: 195..245, timing_secs: 10 } }
  let(:measure_five_config) { { query_count: 120..160, timing_secs: 15, debug: true } }
  let(:measure_six_config) { { query_count: 15..65, timing_secs: 10 } }
  let(:measure_seven_config) { { query_count: 125..155, timing_secs: 10 } }
  let(:hdx_upload_config) { { query_count: 605..655, timing_secs: 10 } }

  let(:measure_configs) do
    [
      { klass: HudSpmReport::Generators::Fy2026::MeasureOne, **measure_one_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureTwo, **measure_two_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureThree, **measure_three_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureFour, **measure_four_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureFive, **measure_five_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureSix, **measure_six_config },
      { klass: HudSpmReport::Generators::Fy2026::MeasureSeven, **measure_seven_config },
      { klass: HudSpmReport::Generators::Fy2026::HdxUpload, **hdx_upload_config },
    ]
  end
end

RSpec.shared_examples 'SPM performance budget validation' do
  it 'limits queries for enrollment creation and each measure run' do
    aggregate_failures('spm enrollment creation') do
      expect do
        # puts "start create enrollment set at #{Time.current.strftime("%H:%M:%S")}"
        HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
        # puts "stop create enrollment set at #{Time.current.strftime("%H:%M:%S")}"
      end.to(
        make_database_queries(count: enrollment_set_query_count).
          and(perform_under(enrollment_set_timing_secs).secs.sample(1).times.warmup(0)),
      )
    end

    expect(report.spm_enrollments.count).to eq(expected_enrollment_count)

    measure_configs.each do |config|
      klass = config[:klass]
      query_count = config[:query_count]
      timing_secs = config[:timing_secs]

      aggregate_failures(klass.name) do
        expect do
          puts "start run_measure #{klass.name} at #{Time.current.strftime("%H:%M:%S")}" if config[:debug]
          prior_level = Rails.logger.level
          Rails.logger.level = 0 if config[:debug]
          run_measure(report, klass)
          Rails.logger.level = prior_level
          puts "completed run_measure #{klass.name} at #{Time.current.strftime("%H:%M:%S")}" if config[:debug]
        end.to(
          make_database_queries(count: query_count).
            and(perform_under(timing_secs).secs.sample(1).times.warmup(0)),
        )

        expect(report.report_cells.where(question: klass.question_number)).to exist
      end
    end
  end
end

RSpec.describe 'FY2026 SPM performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:enrollment_set_query_count) { 40..60 }
  let(:enrollment_set_timing_secs) { 10 }
  let(:question_names) { measure_configs.map { |config| config[:klass].question_number } }

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
  let(:measure_one_config) { { query_count: 145..195, timing_secs: 15 } }
  let(:measure_two_config) { { query_count: 400..450, timing_secs: 15 } }
  let(:measure_three_config) { { query_count: 85..135, timing_secs: 15 } }
  let(:measure_four_config) { { query_count: 195..245, timing_secs: 15 } }
  let(:measure_five_config) { { query_count: 120..160, timing_secs: 15,  } }
  let(:measure_six_config) { { query_count: 15..65, timing_secs: 15 } }
  let(:measure_seven_config) { { query_count: 110..150, timing_secs: 15 } }
  let(:hdx_upload_config) { { query_count: 605..655, timing_secs: 15 } }

  let(:question_names) { measure_configs.map { |config| config[:klass].question_number } }

  include_examples 'SPM performance budget validation'
end

RSpec.describe 'FY2026 SPM performance budget with services', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:enrollment_set_query_count) { 40..60 }
  let(:enrollment_set_timing_secs) { 15 }

  # Only test MeasureOne with service queries
  let(:measure_one_config) { { query_count: 215..265, timing_secs: 15 } }
  let(:measure_configs) do
    [
      { klass: HudSpmReport::Generators::Fy2026::MeasureOne, **measure_one_config },
    ]
  end
  let(:question_names) { measure_configs.map { |config| config[:klass].question_number } }

  before do
    GrdaWarehouse::Hud::Enrollment.preload(:project).find_each do |enrollment|
      7.times do
        create_bed_night_service(enrollment: enrollment, date: enrollment.entry_date) if enrollment.project.project_type == 1
      end
    end
  end

  include_examples 'SPM performance budget validation'
end
