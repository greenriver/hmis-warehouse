###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe HudApr::Generators::Apr::Fy2026::QuestionEight, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:january_pit_date) { Date.new(2026, 1, 28) }

  def run_q8(project_ids)
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: Date.new(2025, 10, 1),
      end: Date.new(2026, 9, 30),
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
    filter.update(project_ids: project_ids)
    report = HudReports::ReportInstance.from_filter(filter, HudApr::Generators::Apr::Fy2026::Generator.title, build_for_questions: ['Question 8'])
    report.update!(question_names: ['Question 8'], started_at: Time.current)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    described_class.new(HudApr::Generators::Apr::Fy2026::Generator.new(report), report).run_question!
    report
  end

  it 'counts a night-by-night household in Q8b when only a member other than the HoH had a bed night' do
    project = create_project(project_type: HudHelper.util('2026').project_type_number_from_code(:es_nbn).first)
    hoh = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
    child = create_client_with_warehouse_link(dob: Date.new(2018, 1, 1))
    hoh_enrollment = create_enrollment(client: hoh, project: project, entry_date: Date.new(2025, 12, 1), household_id: 'H1', relationship_to_ho_h: 1)
    child_enrollment = create_enrollment(client: child, project: project, entry_date: Date.new(2025, 12, 1), household_id: 'H1', relationship_to_ho_h: 2)
    # Night-by-night enrollments need a bed night in the report period to be in the universe
    create_bed_night_service(enrollment: hoh_enrollment, date: january_pit_date - 1.day)
    create_bed_night_service(enrollment: child_enrollment, date: january_pit_date)

    report = run_q8([project.id])

    expect(report.answer(question: 'Q8b', cell: 'B2').summary).to eq(1)
  end
end
