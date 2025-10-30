require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Cohort, type: :model do
  let(:today) { Date.current }
  let!(:ds) { create :grda_warehouse_data_source }
  let!(:destination_data_source) { create :destination_data_source }
  let!(:organization) { create(:hud_organization, data_source: ds) }

  let!(:client) { create :grda_warehouse_hud_client, data_source: destination_data_source }
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
      data_source: ds,
      organization: organization,
      ContinuumProject: 1,
    )
  end
  let!(:source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a1',
      ProjectID: source_project.ProjectID,
      EntryDate: today - 10.days,
      DisablingCondition: 1,
      data_source: ds,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: today - 1.year,
      LivingSituation: 118,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 111,
      EnrollmentCoC: 'MA-500',
    )
  end

  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }
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
      ProjectType: 1, # Emergency Shelter - a homeless project type
      data_source: ds,
      organization: organization,
      ContinuumProject: 1,
    )
  end
  let!(:source_enrollment2) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a2',
      ProjectID: source_project2.ProjectID,
      EntryDate: today - 10.days,
      DisablingCondition: 1,
      data_source: ds,
      PersonalID: source_client2.PersonalID,
      DateToStreetESSH: today - 6.months,
      LivingSituation: 116,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 113,
      EnrollmentCoC: 'MA-500',
    )
  end

  # Same project, earlier date (matches should find source_enrollment)
  let!(:source_enrollment3) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a3',
      ProjectID: source_project.ProjectID,
      EntryDate: today - 100.days,
      DisablingCondition: 1,
      data_source: ds,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: today - 200.days,
      LivingSituation: 117,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 112,
      EnrollmentCoC: 'MA-500',
    )
  end
  # newer but different project, (matches should find source_enrollment)
  let!(:source_enrollment4) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a4',
      ProjectID: source_project2.ProjectID,
      EntryDate: today - 5.days,
      DisablingCondition: 1,
      data_source: ds,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: today - 1.month,
      LivingSituation: 119,
      LOSUnderThreshold: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 114,
      EnrollmentCoC: 'MA-500',
    )
  end
  let!(:project_group) { create :project_group, name: 'Test Group', projects: [source_project] }
  let!(:cohort) { create :cohort, project_group: project_group }

  before do
    # Rebuild service history for all enrollments - required for automation to work
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    cohort.maintain
    cohort.class.prepare_active_cohorts
  end

  describe 'after automation' do
    it 'cohort includes one client' do
      expect(cohort.cohort_clients.pluck(:client_id)).to eq([client.id])
    end
    it 'cohort client has expected values' do
      {
        most_recent_prior_living_situation: HudHelper.util.living_situation(source_enrollment.LivingSituation),
        most_recent_household_type: 'Without Children',
        most_recent_self_report_months_homeless: HudHelper.util.months_homeless_past_three_years(source_enrollment.MonthsHomelessPastThreeYears),
        most_recent_disabling_condition: 'Yes',
      }.each do |col, val|
        expect(cohort.cohort_clients.first.send(col)).to include(val)
      end
      # This is a date, we don't store the full string
      expect(cohort.cohort_clients.first.most_recent_date_to_street).to eq(source_enrollment.DateToStreetESSH)
    end
  end

  describe 'automation filters' do
    include_context 'HUD enrollment builders'

    let!(:project) { create_project(project_type: 1) }
    let!(:project_group) { create(:project_group, projects: [project]) }
    let(:cohort) { create(:cohort) }

    before do
      @client = create_client_with_warehouse_link
      @client_hoh = create_client_with_warehouse_link
      @client_veteran = create_client_with_warehouse_link(veteran_status: 1)

      @client_enrollment = create_enrollment(client: @client, project: project, entry_date: today - 10.days, relationship_to_ho_h: 2)
      @client_hoh_enrollment = create_enrollment(client: @client_hoh, project: project, entry_date: today - 10.days, relationship_to_ho_h: 1)
      @client_veteran_enrollment = create_enrollment(client: @client_veteran, project: project, entry_date: today - 10.days, relationship_to_ho_h: 2)

      # Rebuild service history for all enrollments created so far.
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end

    describe '.auto_maintained' do
      it 'includes cohorts with a project group' do
        expect do
          cohort.update!(project_group: project_group)
        end.to change { described_class.auto_maintained.include?(cohort.reload) }.from(false).to(true)
      end

      it 'includes cohorts with only a sub-population configured' do
        expect do
          cohort.update!(automation_sub_population: 'veterans')
        end.to change { described_class.auto_maintained.include?(cohort.reload) }.from(false).to(true)
      end

      it 'includes cohorts with only hoh_only set' do
        cohort.update!(project_group: nil, automation_sub_population: nil, automation_hoh_only: false)

        expect do
          cohort.update!(automation_hoh_only: true)
        end.to change { described_class.auto_maintained.include?(cohort.reload) }.from(false).to(true)
      end
    end

    describe '#auto_maintained?' do
      it 'is true if project_group_id is set' do
        expect do
          cohort.update!(project_group: project_group)
        end.to change { cohort.auto_maintained? }.from(false).to(true)
      end

      it 'is true if sub_population is set' do
        expect do
          cohort.update!(automation_sub_population: 'veterans')
        end.to change { cohort.auto_maintained? }.from(false).to(true)
      end

      it 'is true if hoh_only is set' do
        expect do
          cohort.update!(automation_hoh_only: true)
        end.to change { cohort.auto_maintained? }.from(false).to(true)
      end
    end

    describe '#automation_scope_descriptions' do
      before { cohort.update!(project_group: project_group) }

      it 'includes the project group when present' do
        expect(cohort.automation_scope_descriptions).to include("projects in the #{project_group.name} project group")
      end

      it 'includes the sub-population label when present' do
        cohort.update!(automation_sub_population: 'veterans')
        expect(cohort.automation_scope_descriptions).to include('clients in the Veterans sub-population')
      end

      it 'includes heads of household when configured' do
        cohort.update!(automation_hoh_only: true)
        expect(cohort.automation_scope_descriptions).to include('clients who are Heads of Household')
      end
    end

    describe '#maintain' do
      before { cohort.update!(project_group: project_group) }
      it 'adds clients from project group' do
        cohort.maintain
        expect(cohort.clients.pluck(:id)).to contain_exactly(
          @client.destination_client.id,
          @client_hoh.destination_client.id,
          @client_veteran.destination_client.id,
        )
      end

      it 'filters by sub-population' do
        expect do
          cohort.update!(automation_sub_population: 'veterans')
          cohort.maintain
        end.to change { cohort.reload.automation_sub_population }.from(nil).to('veterans')

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_veteran.destination_client.id)
      end

      it 'filters by hoh_only' do
        expect do
          cohort.update!(automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_hoh.destination_client.id)
      end

      it 'filters by sub-population and hoh_only' do
        # Create a veteran HoH to test intersection
        client_vet_hoh = create_client_with_warehouse_link(veteran_status: 1)
        create_enrollment(client: client_vet_hoh, project: project, relationship_to_ho_h: 1, entry_date: today - 10.days)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        expect do
          cohort.update!(automation_sub_population: 'veterans', automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_sub_population }.from(nil).to('veterans').
          and change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(client_vet_hoh.destination_client.id)
      end

      it 'removes clients no longer matching criteria' do
        cohort.maintain
        expect(cohort.clients.count).to eq(3)

        expect do
          cohort.update!(automation_hoh_only: true)
          cohort.maintain
        end.to change { cohort.reload.automation_hoh_only }.from(false).to(true)

        expect(cohort.clients.pluck(:id)).to contain_exactly(@client_hoh.destination_client.id)
      end

      it 'removes clients once the enrollment closes' do
        cohort.maintain
        expect(cohort.clients.pluck(:id)).to include(@client.destination_client.id)

        create(
          :hud_exit,
          enrollment: @client_enrollment,
          exit_date: today - 1.day,
          data_source: data_source,
          personal_id: @client.personal_id,
        )

        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

        cohort.maintain

        expect(cohort.clients.pluck(:id)).not_to include(@client.destination_client.id)
      end
    end

    describe 'validations' do
      it 'allows valid sub_population' do
        cohort.automation_sub_population = 'veterans'
        expect(cohort).to be_valid
      end

      it 'rejects invalid sub_population' do
        cohort.automation_sub_population = 'invalid_pop'
        expect(cohort).not_to be_valid
        expect(cohort.errors[:automation_sub_population]).to include('is not a valid sub-population')
      end
    end
  end
end
