###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::RunEnrolledDisabledJob, type: :job do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let(:role_permissions) { { can_view_assigned_reports: true } }
  let!(:role) { create(:role, **role_permissions) }

  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 3) }

  let!(:destination_client) { create(:grda_warehouse_hud_client) }
  let!(:source_client) { create(:grda_warehouse_hud_client, data_source: data_source) }
  let!(:enrollment) do
    create(
      :hud_enrollment,
      data_source: data_source,
      PersonalID: source_client.PersonalID,
      ProjectID: project.ProjectID,
      EntryDate: 1.month.ago.to_date,
    )
  end
  let!(:service_history_entry) do
    create(
      :she_entry,
      client: destination_client,
      data_source_id: data_source.id,
      project_id: project.ProjectID,
      enrollment_group_id: enrollment.EnrollmentID,
      project_type: 3,
      first_date_in_program: enrollment.EntryDate,
      last_date_in_program: nil,
    )
  end

  let(:disability_codes) { HudHelper.util.disability_types.invert }
  let(:hiv_type) { disability_codes.fetch('HIV/AIDS') }
  let(:mental_health_type) { disability_codes.fetch('Mental health disorder') }
  let(:physical_type) { disability_codes.fetch('Physical disability') }

  def create_disability(disability_type)
    create(
      :hud_disability,
      data_source: data_source,
      PersonalID: source_client.PersonalID,
      EnrollmentID: enrollment.EnrollmentID,
      DisabilityType: disability_type,
      DisabilityResponse: 1,
    )
  end

  let!(:hiv_disability) { create_disability(hiv_type) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(
      destination_id: destination_client.id,
      source_id: source_client.id,
      data_source_id: data_source.id,
      id_in_source: source_client.PersonalID,
    )
  end

  def run_report(disability_types: [hiv_type])
    described_class.perform_now(
      {
        filter: {
          start: 2.months.ago.to_date.to_s,
          end: Date.current.to_s,
          # Unknown cohorts apply no population scope, which is the all-clients behavior
          sub_population: 'all_clients',
          disabilities: disability_types.map(&:to_s),
          project_types: ['3'],
          age_ranges: [],
        },
        current_user_id: user.id,
      },
    )
    GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.last
  end

  describe 'when the user cannot view HIV status' do
    it 'drops HIV/AIDS from the requested types and stores an empty report' do
      report = run_report

      expect(report.data).to eq([])
      expect(report.parameters['filter']['disabilities']).to eq([])
    end

    it 'keeps the other requested types' do
      create_disability(physical_type)

      report = run_report(disability_types: [hiv_type, physical_type])

      expect(report.parameters['filter']['disabilities']).to eq([physical_type.to_s])
      expect(report.data.map { |row| row['id'] }).to eq([destination_client.id])
      expect(report.data.first['disabilities']).to eq(['Physical disability'])
    end
  end

  describe 'when the user cannot view mental health status' do
    let!(:mental_health_disability) { create_disability(mental_health_type) }

    it 'drops mental health from the requested types and stores an empty report' do
      report = run_report(disability_types: [mental_health_type])

      expect(report.data).to eq([])
      expect(report.parameters['filter']['disabilities']).to eq([])
    end
  end

  describe 'when the user can view mental health status' do
    let(:role_permissions) { { can_view_assigned_reports: true, can_view_dmh_status: true } }
    let!(:mental_health_disability) { create_disability(mental_health_type) }

    it 'includes clients with the mental health disability' do
      report = run_report(disability_types: [mental_health_type])

      expect(report.data.map { |row| row['id'] }).to eq([destination_client.id])
    end
  end

  describe 'when the user can view HIV status' do
    let(:role_permissions) { { can_view_assigned_reports: true, can_view_hiv_status: true } }

    it 'includes clients with the HIV/AIDS disability' do
      report = run_report

      expect(report.data.map { |row| row['id'] }).to eq([destination_client.id])
    end
  end
end
