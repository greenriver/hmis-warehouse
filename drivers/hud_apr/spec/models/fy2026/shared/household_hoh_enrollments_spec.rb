###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::Generators::Shared::Fy2026::HouseholdHohEnrollments, type: :model do
  let(:data_source) { create(:source_data_source) }
  let(:other_data_source) { create(:source_data_source) }
  let(:project) { create(:hud_project, data_source: data_source) }
  let(:other_project) { create(:hud_project, data_source: other_data_source) }

  def entry(project, household_id:, head_of_household:, first_date:)
    create(
      :she_entry,
      client: create(:hud_client, data_source: project.data_source),
      data_source_id: project.data_source_id,
      project_id: project.ProjectID,
      organization_id: project.OrganizationID,
      household_id: household_id,
      head_of_household: head_of_household,
      first_date_in_program: first_date,
    )
  end

  def result(report_entries, project_ids: [project.id, other_project.id])
    enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.where(id: report_entries.map(&:id))
    described_class.new(enrollment_scope: enrollment_scope, project_ids: project_ids).to_h.transform_values(&:id)
  end

  it 'returns the earliest head of household entry for each report household, including one outside the report entries' do
    member = entry(project, household_id: 'H1', head_of_household: false, first_date: Date.new(2025, 3, 1))
    earliest_head = entry(project, household_id: 'H1', head_of_household: true, first_date: Date.new(2023, 1, 1))
    entry(project, household_id: 'H1', head_of_household: true, first_date: Date.new(2024, 6, 1))

    expect(result([member])).to eq([data_source.id, 'H1'] => earliest_head.id)
  end

  it 'matches a household only to heads of household from its own data source' do
    member = entry(project, household_id: 'H1', head_of_household: false, first_date: Date.new(2025, 3, 1))
    head = entry(project, household_id: 'H1', head_of_household: true, first_date: Date.new(2024, 6, 1))
    entry(other_project, household_id: 'H1', head_of_household: true, first_date: Date.new(2020, 1, 1))

    expect(result([member])).to eq([data_source.id, 'H1'] => head.id)
  end

  it 'keeps households that share an id across data sources apart' do
    member = entry(project, household_id: 'H1', head_of_household: false, first_date: Date.new(2025, 3, 1))
    other_member = entry(other_project, household_id: 'H1', head_of_household: false, first_date: Date.new(2025, 3, 1))
    head = entry(project, household_id: 'H1', head_of_household: true, first_date: Date.new(2024, 6, 1))
    other_head = entry(other_project, household_id: 'H1', head_of_household: true, first_date: Date.new(2020, 1, 1))

    expect(result([member, other_member])).to eq(
      [data_source.id, 'H1'] => head.id,
      [other_data_source.id, 'H1'] => other_head.id,
    )
  end

  it 'ignores head of household entries in projects outside the report' do
    member = entry(project, household_id: 'H1', head_of_household: false, first_date: Date.new(2025, 3, 1))
    head = entry(project, household_id: 'H1', head_of_household: true, first_date: Date.new(2024, 6, 1))
    unreported_project = create(:hud_project, data_source: data_source)
    entry(unreported_project, household_id: 'H1', head_of_household: true, first_date: Date.new(2020, 1, 1))

    expect(result([member], project_ids: [project.id])).to eq([data_source.id, 'H1'] => head.id)
  end
end
