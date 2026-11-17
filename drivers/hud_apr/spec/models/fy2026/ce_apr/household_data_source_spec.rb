###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'FY2026 CE APR households across data sources', type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:other_data_source) { create(:source_data_source) }
  let(:es_project_type) { HudHelper.util('2026').project_type_number_from_code(:es_entry_exit).first }
  let(:report_start) { Date.new(2025, 10, 1) }
  let(:report_end) { Date.new(2026, 9, 30) }

  let(:report) do
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: report_start,
      end: report_end,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
    filter.update(project_ids: [project.id, other_project.id])
    report = HudReports::ReportInstance.from_filter(filter, HudApr::Generators::CeApr::Fy2026::Generator.title, build_for_questions: ['Question 7'])
    report.update!(question_names: ['Question 7'], started_at: Time.current)
    report
  end
  let(:generator) { HudApr::Generators::CeApr::Fy2026::Generator.new(report) }

  let!(:project) { create_ce_project }
  let!(:hoh) { create_client_with_warehouse_link(dob: Date.new(1985, 1, 1)) }
  let!(:hoh_enrollment) { create_enrollment(client: hoh, project: project, entry_date: Date.new(2025, 11, 1), household_id: 'H1') }

  # Data source B: an adult with the same HouseholdID and no CE assessment
  let!(:other_project) { in_data_source(other_data_source) { create_ce_project } }
  let!(:other_adult) { in_data_source(other_data_source) { create_client_with_warehouse_link(dob: Date.new(1990, 1, 1)) } }
  let!(:other_enrollment) do
    in_data_source(other_data_source) do
      create_enrollment(client: other_adult, project: other_project, entry_date: Date.new(2025, 11, 1), household_id: 'H1', relationship_to_ho_h: 3)
    end
  end

  before do
    create_ce_record(:hud_assessment, hoh_enrollment, AssessmentDate: Date.new(2025, 12, 1))
  end

  def create_ce_project
    project = create_project(project_type: es_project_type)
    create(:hud_ce_participation, data_source: project.data_source, ProjectID: project.ProjectID, CEParticipationStatusStartDate: Date.new(2024, 1, 1))
    project
  end

  def create_ce_record(factory, enrollment, **attributes)
    create(factory, data_source: enrollment.data_source, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, **attributes)
  end

  def destination_id(source_client)
    GrdaWarehouse::WarehouseClient.find_by!(source_id: source_client.id).destination_id
  end

  def rebuild_service_history
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  it 'matches an assessed household only to clients in its own data source' do
    rebuild_service_history

    expect(generator.client_scope.pluck(:id)).to contain_exactly(destination_id(hoh))
  end

  it 'keeps a client from another data source with a CE event out of an assessed household' do
    # The event puts the other adult in the client universe on their own
    create_ce_record(:hud_event, other_enrollment, EventDate: Date.new(2025, 12, 15))
    rebuild_service_history

    HudApr::Generators::CeApr::Fy2026::QuestionSeven.new(generator, report).run_question!
    universe = report.universe('Question 7').members.map(&:universe_membership)

    expect(universe.map { |c| [c.client_id, c.household_members.size] }).to eq([[hoh.id, 1]])
  end
end
