require 'rails_helper'

RSpec.describe GrdaWarehouse::Cohort, type: :model do
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:ds) { create :grda_warehouse_data_source }
  let!(:source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source: ds,
      PersonalID: client.PersonalID,
      DOB: 20.years.ago.to_date,
    )
  end
  let!(:warehouse_client) do
    create(
      :warehouse_client,
      destination: client,
      source: source_client,
      data_source_id: ds.id,
    )
  end
  let!(:source_project) do
    create(
      :hud_project,
      ProjectType: 0,
      data_source_id: ds.id,
    )
  end
  let!(:source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a1',
      ProjectID: source_project.ProjectID,
      EntryDate: Date.new(2021, 4, 1),
      DisablingCondition: 1,
      data_source_id: ds.id,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: Date.new(2020, 1, 1),
      LivingSituation: 118,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 111,
    )
  end

  let!(:client2) { create :grda_warehouse_hud_client }
  let!(:source_client2) do
    create(
      :grda_warehouse_hud_client,
      data_source: ds,
      PersonalID: client2.PersonalID,
    )
  end
  let!(:warehouse_client2) do
    create(
      :warehouse_client,
      destination: client2,
      source: source_client2,
      data_source_id: ds.id,
    )
  end
  let!(:source_project2) do
    create(
      :hud_project,
      ProjectType: 1,
      data_source_id: ds.id,
    )
  end
  let!(:source_enrollment2) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a2',
      ProjectID: source_project2.ProjectID,
      EntryDate: Date.new(2021, 4, 1),
      DisablingCondition: 1,
      data_source_id: ds.id,
      PersonalID: source_client2.PersonalID,
      DateToStreetESSH: Date.new(2021, 1, 1),
      LivingSituation: 116,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 113,
    )
  end

  # Same project, earlier date (matches should find source_enrollment)
  let!(:source_enrollment3) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a3',
      ProjectID: source_project.ProjectID,
      EntryDate: Date.new(2019, 4, 1),
      DisablingCondition: 1,
      data_source_id: ds.id,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: Date.new(2018, 1, 1),
      LivingSituation: 117,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 112,
    )
  end
  # newer but different project, (matches should find source_enrollment)
  let!(:source_enrollment4) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a4',
      ProjectID: source_project2.ProjectID,
      EntryDate: Date.new(2023, 4, 1),
      DisablingCondition: 1,
      data_source_id: ds.id,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: Date.new(2023, 1, 1),
      LivingSituation: 119,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 114,
    )
  end
  let!(:project_group) { create :project_group, name: 'Test Group' }
  let!(:cohort) { create :cohort }

  before do
    project_group.projects << source_project
    cohort.update(project_group_id: project_group.id)
    cohort.maintain
    cohort.class.prepare_active_cohorts
  end

  describe 'after automation' do
    it 'cohort includes one client' do
      expect(cohort.cohort_clients.pluck(:client_id)).to eq([client.id])
    end
    it 'cohort client has expected values' do
      {
        most_recent_prior_living_situation: HudUtility2024.living_situation(source_enrollment.LivingSituation),
        most_recent_household_type: 'Without Children',
        most_recent_self_report_months_homeless: HudUtility2024.months_homeless_past_three_years(source_enrollment.MonthsHomelessPastThreeYears),
        most_recent_disabling_condition: 'Yes',
      }.each do |col, val|
        expect(cohort.cohort_clients.first.send(col)).to include(val)
      end
      # This is a date, we don't store the full string
      expect(cohort.cohort_clients.first.most_recent_date_to_street).to eq(source_enrollment.DateToStreetESSH)
    end
  end
end
