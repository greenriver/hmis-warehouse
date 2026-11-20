###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'FY2026 APR households across data sources', type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:other_data_source) { create(:source_data_source) }
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

  it 'keeps households that share a HouseholdID in different data sources apart' do
    project = create_project(project_type: es_project_type)
    adult = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
    create_enrollment(client: adult, project: project, entry_date: Date.new(2025, 11, 1), household_id: 'H1')

    other_project = nil
    child = nil
    in_data_source(other_data_source) do
      other_project = create_project(project_type: es_project_type)
      child = create_client_with_warehouse_link(dob: Date.new(2015, 1, 1))
      create_enrollment(client: child, project: other_project, entry_date: Date.new(2025, 11, 1), household_id: 'H1')
    end

    apr_clients = run_apr([project.id, other_project.id])

    expect(apr_clients.map { |c| [c.client_id, c.household_type, c.household_members.size] }).to contain_exactly(
      [adult.id, 'adults_only', 1],
      [child.id, 'children_only', 1],
    )
    expect(apr_clients.map(&:display_household_id)).to eq(['H1', 'H1'])
  end
end
