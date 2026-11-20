###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'FY2026 APR annual assessment anniversary', type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:es_project_type) { HudHelper.util('2026').project_type_number_from_code(:es_entry_exit).first }

  def run_apr(project_ids)
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: Date.new(2025, 10, 1),
      end: Date.new(2026, 9, 30),
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
    filter.update(project_ids: project_ids)
    report = HudReports::ReportInstance.from_filter(filter, HudApr::Generators::Apr::Fy2026::Generator.title, build_for_questions: ['Question 7'])
    report.update!(question_names: ['Question 7'], started_at: Time.current)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    HudApr::Generators::Apr::Fy2026::QuestionSeven.new(HudApr::Generators::Apr::Fy2026::Generator.new(report), report).run_question!
    HudApr::Fy2020::AprClient.where(report_instance_id: report.id)
  end

  # The first HoH (entry 2024-09-01) puts the anniversary at 2026-09-01, inside the report range.
  # The current HoH's own entry (2025-10-15) would put it past the report end.
  it 'expects an annual assessment from the anniversary of the first head of household, who exited before the report' do
    project = create_project(project_type: es_project_type)
    first_head = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
    create_enrollment(client: first_head, project: project, entry_date: Date.new(2024, 9, 1), exit_date: Date.new(2025, 6, 1), household_id: 'H1')
    current_head = create_client_with_warehouse_link(dob: Date.new(1985, 1, 1))
    create_enrollment(client: current_head, project: project, entry_date: Date.new(2025, 10, 15), household_id: 'H1')

    apr_clients = run_apr([project.id])

    expect(apr_clients.map { |c| [c.client_id, c.annual_assessment_expected] }).to eq([[current_head.id, true]])
  end
end
