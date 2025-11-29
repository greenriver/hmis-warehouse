###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'
require_relative '../../../../../../drivers/hud_spm_report/spec/models/fy2026/shared_context'

RSpec.shared_context 'APR performance dataset', shared_context: :metadata do
  include_context 'HUD DQ FY2026 setup'
  include_context 'SPM test setup'

  let(:projects) do
    [
      create_project(project_type: 0),  # ES
      create_project(project_type: 1),  # ES Night-by-Night
    ]
  end

  let(:household_count) { 5 }
  let(:members_per_household) { 3 }
  let(:enrollments_per_member) { 10 }
  let(:create_bed_nights) { true }
  let(:create_income_benefits) { true }
  let(:expected_apr_client_count) do
    household_count * members_per_household
  end

  let(:report) do
    filter = dq_filter.dup
    filter.require_service_during_range = false
    filter.update(project_ids: projects.map(&:id))

    HudReports::ReportInstance.from_filter(
      filter,
      HudApr::Generators::Dq::Fy2026::Generator.title,
      build_for_questions: question_names,
    ).tap do |instance|
      instance.question_names = question_names
      instance.save!
    end
  end

  before do
    bulk_build_households(
      projects: projects,
      base_entry_date: dq_filter.start,
      household_count: household_count,
      members_per_household: members_per_household,
      enrollments_per_member: enrollments_per_member,
      create_bed_nights: create_bed_nights,
      create_income_benefits: create_income_benefits,
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

RSpec.shared_context 'APR question configs', shared_context: :metadata do
  let(:add_apr_clients_config) { nil }
  let(:question_one_config) { nil }
  let(:question_four_config) { nil }

  let(:add_apr_clients_query_count) { 40 }
  let(:add_apr_clients_timing_secs) { 10 }

  let(:question_names) { all_question_classes.map(&:question_number) }
end

RSpec.shared_examples 'APR performance budget validation' do
  def assert_performance(question_name:, question_config:, range: 10)
    return if question_config.nil?

    question_class = "HudApr::Generators::Dq::Fy2026::#{question_name}".constantize

    query_count = question_config.fetch(:query_count)
    timing_secs = question_config[:timing_secs] || 10

    expect do
      run_dq_question(report, question_class)
    end.to(
      make_database_queries(count: query_range(query_count, range)).
        and(perform_under(timing_secs).secs.sample(1).times.warmup(0)),
    )

    expect(report.report_cells.where(question: question_class.question_number)).to exist
  end

  it 'limits queries for client population and each question run' do
    aggregate_failures do
      range = 10

      # Test add_apr_clients separately
      # Create a question instance to access add_apr_clients method
      generator = HudApr::Generators::Dq::Fy2026::Generator.new(report)
      question = HudApr::Generators::Dq::Fy2026::QuestionOne.new(generator, report)

      expect do
        question.send(:add_apr_clients)
      end.to(
        make_database_queries(count: query_range(add_apr_clients_query_count, range)).
          and(perform_under(add_apr_clients_timing_secs).secs.sample(1).times.warmup(0)),
      )

      # Verify APR clients were created
      apr_clients = HudApr::Fy2020::AprClient.where(report_instance_id: report.id)
      expect(apr_clients.count).to eq(expected_apr_client_count)
      puts "total APR clients: #{expected_apr_client_count}"

      opts = { range: range }

      # Test each question
      assert_performance(question_name: 'QuestionOne', question_config: question_one_config, **opts)
      assert_performance(question_name: 'QuestionFour', question_config: question_four_config, **opts)
    end
  end

  def query_range(value, range)
    (value - range)...(value + range)
  end
end

RSpec.describe 'FY2026 APR QuestionOne performance budget', type: :model, exclude_fixpoints: true do
  include_context 'APR performance dataset'
  include_context 'APR question configs'

  let(:all_question_classes) { [HudApr::Generators::Dq::Fy2026::QuestionOne] }
  let(:question_one_config) { { query_count: 384 } }

  context 'with standard dataset' do
    let(:household_count) { 5 }
    let(:enrollments_per_member) { 7 }

    include_examples 'APR performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }
    # let(:add_apr_clients_query_count) { 200 }
    # let(:add_apr_clients_timing_secs) { 20 }

    include_examples 'APR performance budget validation'
  end
end

RSpec.describe 'FY2026 APR QuestionFour performance budget', type: :model, exclude_fixpoints: true do
  include_context 'APR performance dataset'
  include_context 'APR question configs'

  let(:all_question_classes) { [HudApr::Generators::Dq::Fy2026::QuestionFour] }
  let(:question_four_config) { { query_count: 209 } }

  context 'with standard dataset' do
    let(:household_count) { 5 }
    let(:enrollments_per_member) { 7 }

    include_examples 'APR performance budget validation'
  end

  context 'with large dataset', skip: 'expensive test' do
    let(:household_count) { 200 }
    let(:enrollments_per_member) { 2 }
    # let(:add_apr_clients_query_count) { 200 }
    # let(:add_apr_clients_timing_secs) { 20 }

    include_examples 'APR performance budget validation'
  end
end
