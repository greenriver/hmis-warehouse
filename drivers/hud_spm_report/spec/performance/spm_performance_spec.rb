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

  let(:project_ids) { projects.map(&:id) }
  let(:household_count) { 35 }
  let(:members_per_household) { 3 }
  let(:enrollments_per_member) { 10 }
  let(:expected_enrollment_count) { household_count * members_per_household * enrollments_per_member }

  let(:report) do
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2026',
      build_for_questions: ['Measure 1'],
    ).tap do |instance|
      instance.question_names = ['Measure 1']
      instance.save!
    end
  end

  before do
    puts "building"
    build_performance_households
    puts "done"
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    report # ensure the report is persisted before running expectations
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

RSpec.describe HudSpmReport::Fy2026::SpmEnrollment, type: :model do
  include_context 'SPM performance dataset'

  describe '.create_enrollment_set' do
    it 'executes a bounded number of queries for large households' do
      expect do
        described_class.create_enrollment_set(report)
      end.to make_database_queries(count: 0..90)

      report.reload
      expect(report.spm_enrollments.count).to eq(expected_enrollment_count)
    end
  end
end

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureOne, type: :model do
  include_context 'SPM performance dataset'

  before do
    HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)
    report.reload
  end

  describe 'performance optimizations' do
    it 'runs without introducing n+1 queries' do
      expect do
        run_measure(report, described_class)
      end.to make_database_queries(count: 0..150)

      report.reload
      expect(report.answer(question: '1a', cell: 'B2').summary.to_i).to be_positive
    end
  end
end
