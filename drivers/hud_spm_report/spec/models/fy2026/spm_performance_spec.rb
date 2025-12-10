###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

# exercise the SPM to identify performance issues.
# "standard": about 100 enrollments
# "large": about 1,200 enrollments
# Note:
# the large data sets are expensive to run (almost entirely due to RebuildEnrollmentsByBatchJob, which is not part of the report but is needed to get the data setup). These expensive specs are disabled by default.
#

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

  let(:household_count) { 5 }
  let(:members_per_household) { 3 }
  let(:enrollments_per_member) { 10 }
  let(:create_bed_nights) { false }
  let(:measure_two_pattern) { false }
  let(:create_coc_funders) { false }
  let(:create_income_benefits) { false }
  let(:include_move_in) { false }
  let(:expected_spm_enrollment_count) do
    household_count * members_per_household * enrollments_per_member
  end

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
    # puts "started bulk_build_households at #{Time.current.strftime("%H:%M:%S")}"
    bulk_build_households(
      projects: projects,
      base_entry_date: default_filter.start,
      household_count: household_count,
      members_per_household: members_per_household,
      enrollments_per_member: enrollments_per_member,
      create_bed_nights: create_bed_nights,
      measure_two_pattern: measure_two_pattern,
      create_coc_funders: create_coc_funders,
      create_income_benefits: create_income_benefits,
      include_move_in: include_move_in,
    )
    ServiceHistory::RebuildEnrollmentsByBatchJob.new(
      enrollment_ids: GrdaWarehouse::Tasks::ServiceHistory::Enrollment.pluck(:id),
      progress: false,
    ).perform
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    raise 'expected all enrollments to be processed' unless GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.count.zero?

    report
  end
end

RSpec.shared_context 'SPM measure configs', shared_context: :metadata do
  # Placeholder configs - override in specific test contexts
  let(:measure_one_config) { nil }
  let(:measure_two_config) { nil }
  let(:measure_three_config) { nil }
  let(:measure_four_config) { nil }
  let(:measure_five_config) { nil }
  let(:measure_six_config) { nil }
  let(:measure_seven_config) { nil }
  let(:hdx_upload_config) { nil }

  let(:enrollment_set_query_count) { 40 }
  let(:enrollment_set_timing_secs) { 10 }

  let(:question_names) { all_measure_classes.map(&:question_number) }
end

RSpec.shared_examples 'SPM performance budget validation' do
  def assert_performance(measure_name:, measure_config:, range: 20)
    return if measure_config.nil?

    measure_class = "HudSpmReport::Generators::Fy2026::#{measure_name}".constantize

    query_count = measure_config.fetch(:query_count)
    timing_secs = measure_config[:timing_secs] || 10

    expect do
      run_measure(report, measure_class)
    end.to(
      make_database_queries(count: query_range(query_count, range)).
        and(perform_under(timing_secs).secs.sample(1).times.warmup(0)),
    )

    expect(report.report_cells.where(question: measure_class.question_number)).to exist
  end

  it 'limits queries for enrollment creation and each measure run' do
    aggregate_failures do
      range = 10
      expect do
        HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
      end.to(
        make_database_queries(count: query_range(enrollment_set_query_count, range)).
          and(perform_under(enrollment_set_timing_secs).secs.sample(1).times.warmup(0)),
      )

      expect(report.spm_enrollments.count).to eq(expected_spm_enrollment_count)
      # puts "total enrollments: #{expected_spm_enrollment_count}"

      opts = { range: range }

      # Rails.logger.level = 0
      assert_performance(measure_name: 'MeasureOne', measure_config: measure_one_config, **opts)
      assert_performance(measure_name: 'MeasureTwo', measure_config: measure_two_config, **opts)
      assert_performance(measure_name: 'MeasureThree', measure_config: measure_three_config, **opts)
      assert_performance(measure_name: 'MeasureFour', measure_config: measure_four_config, **opts)
      assert_performance(measure_name: 'MeasureFive', measure_config: measure_five_config, **opts)
      assert_performance(measure_name: 'MeasureSix', measure_config: measure_six_config, **opts)
      assert_performance(measure_name: 'MeasureSeven', measure_config: measure_seven_config, **opts)
      assert_performance(measure_name: 'HdxUpload', measure_config: hdx_upload_config, **opts)
    end
  end

  def query_range(value, range)
    (value - range)...(value + range)
  end
end

RSpec.describe 'FY2026 SPM MeasureOne performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureOne] }
  let(:create_bed_nights) { true }
  let(:measure_one_config) { { query_count: 263 } }
  let(:projects) do
    [
      create_project(project_type: 0),
      create_project(project_type: 1),
      create_project(project_type: 2), # TH - matters for m1a2
      create_project(project_type: 8),
    ]
  end

  context 'with standard dataset' do
    let(:household_count) { 5 }
    let(:enrollments_per_member) { 7 }

    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: true do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }
    let(:measure_one_config) { { query_count: 260 } }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureTwo performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureTwo] }
  let(:measure_two_config) { { query_count: 444 } }
  let(:household_count) { 5 }
  let(:measure_two_pattern) { true }
  let(:expected_spm_enrollment_count) do
    (household_count * members_per_household * enrollments_per_member) * 2
  end

  # Measure Two needs: SO, ES, TH, SH, PH project types
  let(:projects) do
    [
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
      create_project(project_type: 2),  # TH
      create_project(project_type: 4),  # SO
      create_project(project_type: 8),  # SH
      create_project(project_type: 13), # PH
    ]
  end

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }
    let(:enrollment_set_query_count) { 63 }
    let(:enrollment_set_timing_secs) { 20 }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureThree performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureThree] }
  let(:measure_three_config) { { query_count: 166 } }
  let(:household_count) { 5 }
  let(:create_bed_nights) { true }
  let(:projects) do
    [
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
      create_project(project_type: 2),  # TH
      create_project(project_type: 8),  # SH
    ]
  end

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureFour performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureFour] }
  let(:measure_four_config) { { query_count: 260 } }
  let(:household_count) { 5 }
  let(:create_coc_funders) { true }
  let(:create_income_benefits) { true }

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureFive performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureFive] }
  let(:measure_five_config) { { query_count: 171 } }
  let(:household_count) { 5 }

  # Measure 5.1 uses ES, SH, TH
  # Measure 5.2 uses ES, SH, TH, PH
  let(:projects) do
    [
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
      create_project(project_type: 2),  # TH
      create_project(project_type: 3),  # PH
      create_project(project_type: 8),  # SH
    ]
  end

  # Note: Current bulk_build pattern creates all enrollments starting at report period start,
  # so no clients will have prior enrollments in the 24-month lookback. This still exercises
  # the query paths but primarily tests the "first-time homeless" scenario.

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 100 }
    let(:enrollments_per_member) { 2 }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureSix performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  # note, this measure is an empty placeholder, don't bother testing n+1 queries
  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureSix] }
  let(:measure_six_config) { { query_count: 32 } }
  let(:household_count) { 1 }

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM MeasureSeven performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::MeasureSeven] }
  let(:measure_seven_config) { { query_count: 175 } }
  let(:household_count) { 5 }
  let(:include_move_in) { true }

  # Measure 7 uses SO, ES, TH, SH, and PH projects
  let(:projects) do
    [
      create_project(project_type: 4),  # SO
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
      create_project(project_type: 2),  # TH
      create_project(project_type: 3),  # PH
      create_project(project_type: 8),  # SH
    ]
  end

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }

    include_examples 'SPM performance budget validation'
  end
end

RSpec.describe 'FY2026 SPM HdxUpload performance budget', type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'
  include_context 'SPM measure configs'

  let(:all_measure_classes) { [HudSpmReport::Generators::Fy2026::HdxUpload] }
  let(:hdx_upload_config) { { query_count: 2609 } }
  let(:household_count) { 5 }
  let(:projects) do
    [
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
      create_project(project_type: 2),  # TH
      create_project(project_type: 3),  # PH (PSH)
      create_project(project_type: 4),  # SO
      create_project(project_type: 8),  # SH
      create_project(project_type: 13), # RRH
    ]
  end

  context 'with standard dataset' do
    include_examples 'SPM performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }

    include_examples 'SPM performance budget validation'
  end
end
