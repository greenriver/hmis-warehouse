###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# Shared context for SPM testing
RSpec.shared_context 'SPM test setup', shared_context: :metadata do
  include_context 'HUD enrollment builders'
  let(:household_sequence) do
    Enumerator.new do |y|
      i = 0
      loop { y << "HH-#{SecureRandom.uuid}-#{i += 1}" }
    end
  end

  let(:default_filter) do
    Filters::HudFilterBase.new(
      user: user,
      start: '2022-10-01'.to_date,
      end: '2023-09-30'.to_date,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
  end

  def build_household(projects:, entry_date:, exit_date:, members: 1, destination: nil, living_situation: 100, date_to_street_essh: nil, include_move_in: false, move_in_offset: 0, data_source_override: nil, household_id: nil) # rubocop:disable Metrics/ParameterLists
    household_id ||= household_sequence.next
    members.times.flat_map do |index|
      client = create_client_with_warehouse_link
      relationship = index.zero? ? 1 : 2
      projects.map do |project|
        move_in_date = nil
        move_in_date = entry_date + move_in_offset if include_move_in && relationship == 1
        create_enrollment(
          client: client,
          project: project,
          entry_date: entry_date,
          exit_date: exit_date,
          relationship_to_ho_h: relationship,
          date_to_street_essh: date_to_street_essh,
          household_id: household_id,
          living_situation: living_situation,
          destination: destination,
          move_in_date: move_in_date,
        ).tap do |enrollment|
          enrollment.update!(data_source: data_source_override) if data_source_override
          yield client, enrollment if block_given?
        end
      end
    end
  end

  def add_income_snapshot(enrollment:, information_date:, data_collection_stage:, earned_amount:, other_income_amount:)
    total_income = earned_amount.to_f + other_income_amount.to_f
    create(
      :hud_income_benefit,
      enrollment: enrollment,
      data_source: enrollment.data_source,
      information_date: information_date,
      data_collection_stage: data_collection_stage,
      earned_amount: earned_amount,
      total_monthly_income: total_income,
      other_income_amount: other_income_amount,
    )
  end

  def add_bed_nights(enrollment:, start_date:, end_date:)
    (start_date...end_date).each do |date|
      create_bed_night_service(enrollment: enrollment, date: date)
    end
  end

  def build_return_scenario(project:, entry_date:, exit_date:, destination:, return_entry_date:, return_exit_date:)
    client = create_client_with_warehouse_link
    enrollment = create_enrollment(
      client: client,
      project: project,
      entry_date: entry_date,
      exit_date: exit_date,
      relationship_to_ho_h: 1,
      destination: destination,
      living_situation: 1,
    )
    return_enrollment = create_enrollment(
      client: client,
      project: project,
      entry_date: return_entry_date,
      exit_date: return_exit_date,
      relationship_to_ho_h: 1,
      living_situation: 1,
    )
    [client, enrollment, return_enrollment]
  end

  def setup_report(project_ids, questions = ['Measure 1'])
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2026',
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!

    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Generate the SpmEnrollment records
    HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)

    report
  end

  def run_measure(report, measure_class)
    report.started_at ||= Time.current
    report.save! if report.changed?

    generator = HudSpmReport::Generators::Fy2026::Generator.new(report)
    measure = measure_class.new(generator, report)
    measure.run_question!
    report.reload
  end
end
