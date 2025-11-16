###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../models/fy2026/shared_context'

RSpec.shared_context 'SPM performance dataset', shared_context: :metadata do
  include_context 'SPM test setup'

  let(:projects) do
    [
      create_project(project_type: 0), # ES-EE
      create_project(project_type: 2), # TH
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
    puts "testing before a #{Time.current.strftime("%H:%M:%S")}"
    build_performance_households
    puts "testing before b #{Time.current.strftime("%H:%M:%S")}"
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    puts "testing before c #{Time.current.strftime("%H:%M:%S")}"
    report
    puts "testing before d #{Time.current.strftime("%H:%M:%S")}"
    # Rails.logger.level = 0
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
          entry_date = base_entry_date + (household_index * 3 + enrollment_index).days
          exit_date = entry_date + 20.days

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
            move_in_date: relationship == 1 ? entry_date + 5.days : nil,
          )
        end
      end
    end
  end
end

RSpec.shared_examples 'SPM measure performance check' do
  before do
    HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
  end

  it 'runs within the expected query budget and persists answers' do
    aggregate_failures 'performance' do
      expect do
        puts "testing ##{question_names.inspect} a #{Time.current.strftime("%H:%M:%S")}"
        run_measure(report, measure_class)
      end.to make_database_queries(count: query_range).
        and perform_under(timing_ms).ms.sample(1).times.warmup(0)
    end
    puts "testing ##{question_names.inspect} b #{Time.current.strftime("%H:%M:%S")}"

    expect(report.report_cells.where(question: measure_class.question_number)).to exist
  end
end

RSpec.describe HudSpmReport::Fy2026::SpmEnrollment, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:question_names) do
    ['Measure 1', 'Measure 2', 'Measure 3', 'Measure 4', 'Measure 5', 'Measure 6', 'Measure 7', 'HDX Upload']
  end
  let(:query_range) { 45..55 }
  let(:timing_ms) { 30 * 1000 }

  describe '.create_enrollment_set' do
    it 'executes a bounded number of queries for large households' do
      aggregate_failures 'performance' do
        expect do
          puts "testing create_enrollment_set a #{Time.current.strftime("%H:%M:%S")}"
          described_class.create_enrollment_set(report)
        end.to make_database_queries(count: query_range).
          and perform_under(timing_ms).ms.sample(1).times.warmup(0)
      end
      puts "testing create_enrollment_set b #{Time.current.strftime("%H:%M:%S")}"

      expect(report.spm_enrollments.count).to eq(expected_enrollment_count)
    end
  end
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureOne, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 250..260 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureTwo, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 410..430 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureThree, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 170..190 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureFour, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 210..230 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureFive, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 350..380 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureSix, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 30..40 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureSeven, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 245..265 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end

RSpec.describe HudSpmReport::Generators::Fy2026::HdxUpload, type: :model, exclude_fixpoints: true do
  include_context 'SPM performance dataset'

  let(:measure_class) { described_class }
  let(:question_names) { [measure_class.question_number] }
  let(:query_range) { 1230..1250 }
  let(:timing_ms) { 30 * 1000 }

  include_examples 'SPM measure performance check'
end
