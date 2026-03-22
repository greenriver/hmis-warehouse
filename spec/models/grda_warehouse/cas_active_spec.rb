# frozen_string_literal: true

require 'rails_helper'

# Specs for CAS "active clients" sync: who is considered active for CAS matching based on
# service history, project groups, and manual overrides.
RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  # Base setup: active_clients method, extrapolated days enabled, cas_activity_methods fixture
  # (Client 1-1: ES enrollment + services; Client 1-2: SO + CE enrollments)
  shared_context 'active_clients with cas_activity_methods fixture' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: true,
        cas_sync_months: 1,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end
  end

  # Asserts both active_in_cas? and cas_active scope agree on count
  def expect_active_cas_count(expected)
    expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(expected)
    expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(expected)
  end

  # Creates project group with filter, maintains projects, sets config to use it
  def setup_active_clients_project_group(name:, project_type_numbers:, excluded_project_ids:)
    @cas_project_group = GrdaWarehouse::ProjectGroup.create!(name: name)
    @cas_project_group.update(
      options: @cas_project_group.filter.update(
        project_type_numbers: project_type_numbers,
        excluded_project_ids: excluded_project_ids,
      ).to_h,
    )
    @cas_project_group.maintain_projects!
    @config.update(cas_sync_project_group_id: @cas_project_group.id)
  end
  # Extrapolated days: SO day-as-month counts as service; both clients have enrollments in range
  describe 'when including extrapolated enrollments' do
    include_context 'active_clients with cas_activity_methods fixture'

    it 'finds two clients who are active for CAS' do
      # Feb 2016: both clients have extrapolated service in ES/SO/CE
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(2) }
    end

    it 'finds no client who is active for CAS' do
      # Mar 2016: outside sync range, no one active
      travel_to Time.local(2016, 3, 15) { expect_active_cas_count(0) }
    end

    it 'excludes clients enrolled in non-Homeless/non-CE project types' do
      # Day Shelter (11) is not homeless/CE; no one qualifies without override
      GrdaWarehouse::Hud::Project.update_all(ProjectType: 11)
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(0) }
    end

    it 'includes clients enrolled in projects active_homeless_status_override' do
      # Day Shelter with override counts as homeless; both clients qualify
      GrdaWarehouse::Hud::Project.update_all(ProjectType: 11, active_homeless_status_override: true)
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(2) }
    end
  end

  # No extrapolation: only clients with actual service records count
  describe 'when excluding extrapolated enrollments' do
    before(:all) do
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: false,
        cas_sync_months: 1,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'finds one client who is active for CAS' do
      # Only client 1-1 has actual services in range; 1-2 has none
      travel_to Time.local(2016, 2, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(1)
      end
    end

    it 'finds no client who is active for CAS' do
      # Mar 2016: outside sync range
      travel_to Time.local(2016, 3, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(0)
        expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(0)
      end
    end
  end

  # Project group with exclusions: ES excluded, only SO and CE count
  describe 'when active_clients with project group excluding some projects' do
    include_context 'active_clients with cas_activity_methods fixture'

    before(:all) do
      es_project = GrdaWarehouse::Hud::Project.find_by(project_id: '1-1')
      setup_active_clients_project_group(
        name: 'CAS sync excluding ES',
        project_type_numbers: [1, 4, 14],
        excluded_project_ids: [es_project.id],
      )
    end
    after(:all) { @cas_project_group.destroy }

    it 'excludes clients whose only service is in excluded projects' do
      # Client 1-1: only in ES (excluded) -> not active. Client 1-2: SO+CE (in group) -> active
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(1) }
    end

    it 'with no project group set, uses default homeless+CE (2 clients with extrapolated)' do
      # Clearing project group falls back to all homeless+CE; both clients qualify
      @config.update(cas_sync_project_group_id: nil)
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(2) }
      @config.update(cas_sync_project_group_id: @cas_project_group.id)
    end
  end

  # Project group includes ES, SO, CE; no exclusions
  describe 'when active_clients with project group including all projects' do
    include_context 'active_clients with cas_activity_methods fixture'

    before(:all) do
      setup_active_clients_project_group(
        name: 'CAS sync all homeless CE',
        project_type_numbers: [1, 4, 14],
        excluded_project_ids: [],
      )
    end
    after(:all) { @cas_project_group.destroy }

    it 'includes es_project enrollment when project group has no exclusions' do
      # Both clients active: 1-1 via ES, 1-2 via SO/CE
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(2) }
    end
  end

  # Project group = SO+CE only. ES is Day Shelter with override but NOT in group.
  # Override projects are NOT auto-included when a project group is configured.
  describe 'when active_clients with project group - active_homeless_status_override not auto-included' do
    include_context 'active_clients with cas_activity_methods fixture'

    before(:all) do
      GrdaWarehouse::Hud::Project.find_by(project_id: '1-1').
        update!(ProjectType: 11, active_homeless_status_override: true)
      setup_active_clients_project_group(
        name: 'CAS sync SO and CE only',
        project_type_numbers: [4, 14],
        excluded_project_ids: [],
      )
    end
    after(:all) { @cas_project_group.destroy }

    it 'does not auto-include override projects when project group is set' do
      # Client 1-1 only in ES (override, not in group) -> not active. Client 1-2 in SO/CE -> active
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(1) }
    end

    it 'with no project group, override projects are included (2 clients)' do
      # No project group: default includes homeless+CE+override; both clients qualify
      @config.update(cas_sync_project_group_id: nil)
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(2) }
      @config.update(cas_sync_project_group_id: @cas_project_group.id)
    end
  end

  # Project group filters to type 99 (no matching projects) -> empty effective project list
  describe 'when active_clients with empty project group' do
    include_context 'active_clients with cas_activity_methods fixture'

    before(:all) do
      setup_active_clients_project_group(
        name: 'CAS sync empty',
        project_type_numbers: [99],
        excluded_project_ids: [],
      )
    end
    after(:all) { @cas_project_group.destroy }

    it 'finds no client when project group has no projects' do
      # No projects in group -> no one qualifies by service (no sync_with_cas set in this setup)
      travel_to Time.local(2016, 2, 15) { expect_active_cas_count(0) }
    end
  end

  # All projects Day Shelter (no homeless/CE) -> project_ids blank. Manual sync_with_cas flag overrides.
  describe 'when active_clients with sync_with_cas override' do
    include_context 'active_clients with cas_activity_methods fixture'

    before(:all) do
      GrdaWarehouse::Hud::Project.update_all(ProjectType: 11)
      @client_with_flag = GrdaWarehouse::Hud::Client.destination.first
      @client_with_flag.update!(sync_with_cas: true)
    end

    it 'cas_active scope includes clients with sync_with_cas when no one qualifies by service' do
      # Scope uses .or(sync_with_cas: true) when project_ids blank; flagged client included
      travel_to Time.local(2016, 2, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.cas_active).to include(@client_with_flag)
      end
    end

    it 'active_in_cas? returns true for client with sync_with_cas when no one qualifies by service' do
      # Instance method also respects sync_with_cas override when project_ids blank
      travel_to Time.local(2016, 2, 15) { expect(@client_with_flag.active_in_cas?).to be true }
    end
  end

  # cas_available_method: project_group — active = ongoing enrollment in group's projects
  describe 'when syncing by project group' do
    before(:all) do
      @cas_project_group = GrdaWarehouse::ProjectGroup.create!(name: 'test')
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :project_group,
        cas_sync_project_group_id: @cas_project_group.id,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      @cas_project_group.destroy
    end

    describe 'with no projects in the project group' do
      before(:all) { @cas_project_group.projects = [] }

      it 'finds no client who is active for CAS' do
        # Empty group -> no ongoing enrollments in group
        clients = GrdaWarehouse::Hud::Client.destination.select(&:active_in_cas?)
        error_message = "Clients: #{clients.map(&:FirstName).join('; ')}"
        expect(clients.count).to eq(0), error_message
        expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(0)
      end
    end

    describe 'with one project in the project group' do
      before(:all) do
        @cas_project_group.projects.delete_all
        @cas_project_group.projects << GrdaWarehouse::Hud::Project.find_by(project_id: '1-1')
      end

      it 'finds one client who is active for CAS' do
        # Group has only ES (1-1). Client 1-1 enrolled there; client 1-2 in SO/CE only
        aggregate_failures do
          travel_to Time.zone.local(2016, 2, 1) do
            expect(GrdaWarehouse::Hud::Project.count).to eq(3)
            expect(@cas_project_group.projects.count).to eq(1)
            expect(GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing.count).to eq(2)
            expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
            expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(1)
          end
        end
      end
    end
  end

  # cas_available_method: ce_with_assessment — active = CE enrollment with assessment
  describe 'when syncing by ce enrollment' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :ce_with_assessment,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'finds one client who is active for CAS' do
      # Client 1-1 has CE enrollment (1-4) with assessment; CE enrollments start 2017-01-01
      travel_to Time.local(2017, 2, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.cas_active.count).to eq(1)
      end
    end
  end
end
