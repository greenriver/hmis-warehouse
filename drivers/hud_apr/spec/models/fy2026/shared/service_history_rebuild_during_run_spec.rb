###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

# 9014 item 5. Nightly processing can rebuild a night-by-night enrollment's service history while an
# APR-family report runs. The rebuild replaces the enrollment's rows with new ones (new ids), so a
# report that evaluates the client afterwards must still count them.
#
# The race is forced at the point where it hurts most: after an earlier batch has been evaluated
# and immediately before the client's own batch is evaluated in the pass that builds report
# clients. Q7b covers both the night-by-night service check and the PIT bed-night check.
#
# Transactional: the report and the rebuild are sequential in one session.
RSpec.describe HudApr::Generators::Apr::Fy2026::QuestionSeven, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:january_pit_date) { Date.new(2026, 1, 28) }
  let(:es_nbn) { HudHelper.util('2026').project_type_number_from_code(:es_nbn).first }
  let!(:project) { create_project(project_type: es_nbn) }

  # Created first, so this client's destination id sorts first and their batch is evaluated first
  let!(:earlier_client) { create_client_with_warehouse_link }
  let!(:rebuilt_client) { create_client_with_warehouse_link }
  let!(:earlier_enrollment) { create_nbn_enrollment(earlier_client) }
  let!(:rebuilt_enrollment) { create_nbn_enrollment(rebuilt_client) }
  let(:rebuilt_destination_id) { rebuilt_client.destination_client.id }

  let(:report) do
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: Date.new(2025, 10, 1),
      end: Date.new(2026, 9, 30),
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
    filter.update(project_ids: [project.id])
    report = HudReports::ReportInstance.from_filter(
      filter,
      HudApr::Generators::Apr::Fy2026::Generator.title,
      build_for_questions: ['Question 7'],
    )
    report.update!(question_names: ['Question 7'], started_at: Time.current)
    report
  end
  let(:question) do
    generator = HudApr::Generators::Apr::Fy2026::Generator.new(report)
    described_class.new(generator, report)
  end

  before do
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    # One client per batch, so the run evaluates an earlier batch before the rebuilt client's
    allow(question).to receive(:batch_size).and_return(1)
  end

  def create_nbn_enrollment(client)
    enrollment = create_enrollment(client: client, project: project, entry_date: Date.new(2025, 12, 1))
    create_bed_night_service(enrollment: enrollment, date: january_pit_date)
    enrollment
  end

  def entry_row_id_for(enrollment)
    GrdaWarehouse::ServiceHistoryEnrollment.entry.
      find_by(data_source_id: enrollment.data_source_id, enrollment_group_id: enrollment.EnrollmentID).
      id
  end

  # Seam: run the rebuild immediately before the rebuilt client's batch is evaluated for the second
  # time (the household pass evaluates it first, then the pass that builds report clients). Returns
  # a hash that records the entry row ids before and after the rebuild.
  def rebuild_before_client_pass_evaluates_rebuilt_client
    rebuild = {}
    evaluations = 0
    allow(question).to receive(:clients_with_enrollments).and_wrap_original do |original, batch, **options|
      if batch.map(&:id).include?(rebuilt_destination_id)
        evaluations += 1
        if evaluations == 2
          rebuild[:entry_id_before] = entry_row_id_for(rebuilt_enrollment)
          rebuilder = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(rebuilt_enrollment.id)
          rebuilder.create_service_history!(true)
          rebuild[:entry_id_after] = entry_row_id_for(rebuilt_enrollment)
        end
      end
      original.call(batch, **options)
    end
    rebuild
  end

  def report_client_ids
    HudApr::Fy2020::AprClient.where(report_instance_id: report.id).pluck(:destination_client_id)
  end

  def january_pit_total
    report.answer(question: 'Q7b', cell: 'B2').summary
  end

  it 'counts a night-by-night client whose service history was rebuilt during the run' do
    pending('9014 item 5: night-by-night service and PIT bed nights are matched by service history ids memoized for the run')
    rebuild = rebuild_before_client_pass_evaluates_rebuilt_client

    question.run_question!

    # Guard: the rebuild happened mid-run and replaced the entry row
    expect(rebuild[:entry_id_after]).to be_present
    expect(rebuild[:entry_id_after]).not_to eq(rebuild[:entry_id_before])
    expect(report_client_ids).to include(rebuilt_destination_id)
    expect(january_pit_total).to eq(2)
  end

  it 'counts both night-by-night clients when nothing is rebuilt during the run' do
    question.run_question!

    expect(report_client_ids).to contain_exactly(earlier_client.destination_client.id, rebuilt_destination_id)
    expect(january_pit_total).to eq(2)
  end
end
