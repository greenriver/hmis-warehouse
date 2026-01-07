# frozen_string_literal: true

require 'rails_helper'
require_relative 'dq/shared_context'

RSpec.describe 'APR Data Source Isolation', type: :model do
  include_context 'HUD DQ FY2026 setup'

  let(:ds1) { create(:source_data_source, id: 100, name: 'Vendor 1') }
  let(:ds2) { create(:source_data_source, id: 200, name: 'Vendor 2') }

  let(:shared_hh_id) { 'COLLISION-123' }

  # Helpers to create isolated data sets using shared builder patterns
  def create_isolated_project(data_source, project_type: 1)
    # Ensure Organization exists so the inner join doesn't fail
    org = create(:hud_organization, data_source: data_source)

    project = create(:hud_project,
      data_source: data_source,
      organization: organization,
      project_type: project_type,
      continuum_project: 1
    )
    # Ensure ProjectCoC exists so the filter discovers the project
    create(:hud_project_coc,
      project: project,
      data_source: data_source,
      coc_code: 'MA-500'
    )
    project
  end

  def create_isolated_client(data_source, first_name:, last_name:, personal_id:)
    client = create(:hud_client,
      data_source: data_source,
      FirstName: first_name,
      LastName: last_name,
      PersonalID: personal_id
    )
    # Warehouse link is required for SHE rebuilding
    create(:warehouse_client,
      source: client,
      destination: create(:hud_client, data_source: destination_data_source)
    )
    client
  end

  it 'prevents PII leakage across data sources when HouseholdIDs collide' do
    # --- Data Source 1 ---
    project1 = create_isolated_project(ds1)
    client1 = create_isolated_client(ds1, first_name: 'Alice', last_name: 'Vendor1', personal_id: 'P1')
    enrollment1 = create(:hud_enrollment,
      data_source: ds1,
      EnrollmentID: 'E1',
      PersonalID: client1.PersonalID,
      ProjectID: project1.ProjectID,
      HouseholdID: shared_hh_id,
      EntryDate: '2025-10-01',
      EnrollmentCoC: 'MA-500',
    )

    # --- Data Source 2 ---
    project2 = create_isolated_project(ds2)
    client2 = create_isolated_client(ds2, first_name: 'Bob', last_name: 'Vendor2', personal_id: 'P2')
    enrollment2 = create(:hud_enrollment,
      data_source: ds2,
      EnrollmentID: 'E2',
      PersonalID: client2.PersonalID,
      ProjectID: project2.ProjectID,
      HouseholdID: shared_hh_id,
      EntryDate: '2025-10-01',
      EnrollmentCoC: 'MA-500',
    )

    # Rebuild service history to create SHE entries
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Setup report for both projects
    report = setup_dq_report([project1.id, project2.id], ['Question 4'])

    # Debug
    generator = HudApr::Generators::Dq::Fy2026::Generator.new(report)
    puts "Generator client scope SQL: #{generator.client_scope.to_sql}"
    puts "Generator client scope count: #{generator.client_scope.count}"

    # Run preparation (builds HouseholdContext)
    generator.prepare_report

    # Run the report question (builds AprClient)
    HudApr::Generators::Dq::Fy2026::QuestionFour.new(generator, report).run!
    report.reload

    # --- Verification ---
    apr_clients = HudApr::Fy2020::AprClient.where(report_instance_id: report.id).index_by(&:data_source_id)

    expect(apr_clients.count).to eq(2)

    alice_client = apr_clients[ds1.id]
    bob_client = apr_clients[ds2.id]

    expect(alice_client.first_name).to eq('Alice')
    expect(bob_client.first_name).to eq('Bob')

    # FAILURE POINT 1: Household members should only contain members from the SAME data source
    alice_hh_members = alice_client.household_members
    bob_hh_members = bob_client.household_members

    # If it leaked, Alice will see Bob or vice versa in her JSON blob
    expect(alice_hh_members.map { |m| m['source_client_id'] }).to contain_exactly(client1.id)
    expect(bob_hh_members.map { |m| m['source_client_id'] }).to contain_exactly(client2.id)
  end

  it 'isolates HouseholdContext pre-computations by data_source_id' do
    # Scenario: One data source has a 1-person household, another has a 2-person household with same ID.
    project1 = create_isolated_project(ds1)
    project2 = create_isolated_project(ds2)

    # DS1: 1 person
    c1 = create_isolated_client(ds1, first_name: 'C1', last_name: 'DS1', personal_id: 'C1')
    e1 = create(:hud_enrollment, data_source: ds1, ProjectID: project1.ProjectID, HouseholdID: shared_hh_id, PersonalID: c1.PersonalID, EntryDate: '2025-10-01')

    # DS2: 2 people
    c2 = create_isolated_client(ds2, first_name: 'C2', last_name: 'DS2', personal_id: 'C2')
    c3 = create_isolated_client(ds2, first_name: 'C3', last_name: 'DS2', personal_id: 'C3')
    e2 = create(:hud_enrollment, data_source: ds2, ProjectID: project2.ProjectID, HouseholdID: shared_hh_id, PersonalID: c2.PersonalID, EntryDate: '2025-10-01', RelationshipToHoH: 1)
    e3 = create(:hud_enrollment, data_source: ds2, ProjectID: project2.ProjectID, HouseholdID: shared_hh_id, PersonalID: c3.PersonalID, EntryDate: '2025-10-01', RelationshipToHoH: 2)

    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    she1 = GrdaWarehouse::ServiceHistoryEnrollment.find_by!(enrollment_group_id: e1.EnrollmentID, data_source_id: ds1.id)
    she2 = GrdaWarehouse::ServiceHistoryEnrollment.find_by!(enrollment_group_id: e2.EnrollmentID, data_source_id: ds2.id)
    she3 = GrdaWarehouse::ServiceHistoryEnrollment.find_by!(enrollment_group_id: e3.EnrollmentID, data_source_id: ds2.id)

    report = setup_dq_report([project1.id, project2.id], ['Question 4'])
    generator = HudApr::Generators::Dq::Fy2026::Generator.new(report)
    generator.prepare_report

    contexts = HudReports::HouseholdContext.where(report_instance_id: report.id).index_by(&:service_history_enrollment_id)

    # FAILURE POINT 2: Member count should be isolated
    expect(contexts[she1.id]).to be_present
    expect(contexts[she1.id].member_count).to eq(1)
    expect(contexts[she2.id]).to be_present
    expect(contexts[she2.id].member_count).to eq(2)
    expect(contexts[she3.id]).to be_present
    expect(contexts[she3.id].member_count).to eq(2)
  end
end
