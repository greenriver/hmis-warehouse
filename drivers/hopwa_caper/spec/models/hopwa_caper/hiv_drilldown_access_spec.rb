###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::HivDrilldownAccess, type: :model do
  include_context 'HOPWA CAPER shared context'

  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project_a) { create_hopwa_project(funder: tbra_funder) }
  let(:project_b) { create_hopwa_project(funder: tbra_funder) }
  let(:hiv_role) { create(:role, can_view_hiv_status: true) }
  let(:client_a) { create_client_with_warehouse_link(first_name: 'Ann', last_name: 'Able') }
  let(:client_b) { create_client_with_warehouse_link(first_name: 'Bo', last_name: 'Baker') }

  def enroll(client, project)
    create_hiv_positive_enrollment(
      client: client,
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
  end

  def destination_id(client)
    client.destination_client.id
  end

  def access_for(enrollments: report.hopwa_caper_enrollments, services: report.hopwa_caper_services, mode: :browse, for_user: user)
    described_class.new(user: for_user, enrollments: enrollments, services: services, mode: mode)
  end

  context 'with one client on one project' do
    let(:report) { create_report([project_a]) }

    before do
      enroll(client_a, project_a)
      run_report(report)
    end

    it 'allows when the project grants HIV status' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)

      expect(access_for.allowed?).to be(true)
    end

    it 'denies when the role lacks HIV status on the project' do
      expect(report.hopwa_caper_enrollments.count).to eq(1)

      expect(access_for.allowed?).to be(false)
    end

    it 'denies a restricted client even when the project grants HIV status' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      hmis_user = create(:hmis_user, data_source: data_source)
      Hmis::Hud::Client.find(client_a.id).mark_as_restricted!(user: hmis_user)

      expect(access_for.allowed?).to be(false)
    end

    it 'denies a row with no project' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      report.hopwa_caper_enrollments.update_all(project_id: nil)

      expect(access_for.allowed?).to be(false)
    end

    it 'denies when the role grants other client data permissions but not HIV status' do
      role = create(:role, can_view_clients: true, can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true, can_view_hiv_status: false)
      grant_project_access(user, role, [project_a], mode: :acl)

      expect(access_for.allowed?).to be(false)
    end

    it 'denies a legacy user whose role grants other client data permissions but not HIV status' do
      legacy_user = create(:user)
      role = create(:role, can_view_clients: true, can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true, can_view_hiv_status: false)
      grant_project_access(legacy_user, role, [project_a], mode: :legacy)

      expect(access_for(for_user: legacy_user).allowed?).to be(false)
    end

    it 'allows a legacy user whose role grants HIV status on the project' do
      legacy_user = create(:user)
      grant_project_access(legacy_user, hiv_role, [project_a], mode: :legacy)

      expect(access_for(for_user: legacy_user).allowed?).to be(true)
    end

    it 'denies a legacy user whose role lacks HIV status' do
      legacy_user = create(:user)
      grant_project_access(legacy_user, create(:role, can_view_hiv_status: false), [project_a], mode: :legacy)

      expect(access_for(for_user: legacy_user).allowed?).to be(false)
    end

    it 'denies downloads when detail downloads exclude PII, even with HIV access' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)

      expect(access_for(mode: :download).allowed?).to be(false)
      expect(access_for(mode: :browse).allowed?).to be(true)
    end
  end

  context 'with clients on two projects' do
    let(:report) { create_report([project_a, project_b]) }

    before do
      enroll(client_a, project_a)
      enroll(client_b, project_b)
      run_report(report)
    end

    it 'denies when HIV status is granted on only one of the projects' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)

      expect(report.hopwa_caper_enrollments.pluck(:project_id).uniq).to contain_exactly(project_a.id, project_b.id)
      expect(access_for(enrollments: report.hopwa_caper_enrollments.where(project_id: project_a.id)).allowed?).to be(true)
      expect(access_for.allowed?).to be(false)
    end
  end

  context 'with a client enrolled in both projects' do
    let(:report) { create_report([project_a, project_b]) }

    before do
      enroll(client_a, project_a)
      enroll(client_a, project_b)
      run_report(report)
    end

    it 'denies when HIV status is granted on only one of the projects' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      scoped = report.hopwa_caper_enrollments.where(destination_client_id: destination_id(client_a))

      expect(scoped.pluck(:project_id)).to contain_exactly(project_a.id, project_b.id)
      expect(access_for(enrollments: scoped.where(project_id: project_a.id)).allowed?).to be(true)
      expect(access_for(enrollments: scoped).allowed?).to be(false)
    end
  end

  context 'with service rows' do
    let(:report) { create_report([project_a, project_b]) }

    before do
      service_records_a
      create_enrolled_client_with_service(client_attrs: {}, project: project_b, entry_date: report_start_date)
      run_report(report)
    end

    let(:service_records_a) { create_enrolled_client_with_service(client_attrs: {}, project: project_a, entry_date: report_start_date) }

    let(:missing_enrollment_id) { 999_999_999 }

    def services_on(project)
      enrollment_ids = report.hopwa_caper_enrollments.where(project_id: project.id).pluck(:enrollment_id)
      report.hopwa_caper_services.where(enrollment_id: enrollment_ids)
    end

    it 'denies a service whose enrollment project lacks HIV status, with no enrollment rows' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)

      expect(services_on(project_b).count).to be >= 1
      expect(access_for(enrollments: HopwaCaper::Enrollment.none, services: services_on(project_b)).allowed?).to be(false)
      expect(access_for(enrollments: HopwaCaper::Enrollment.none, services: services_on(project_a)).allowed?).to be(true)
    end

    it 'denies a restricted client who appears only in the service rows' do
      grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)
      no_enrollments = HopwaCaper::Enrollment.none
      Hmis::Hud::Client.find(service_records_a[:client].id).mark_as_restricted!(user: create(:hmis_user, data_source: data_source))

      expect(access_for(enrollments: no_enrollments, services: services_on(project_b)).allowed?).to be(true)
      expect(access_for(enrollments: no_enrollments, services: services_on(project_a)).allowed?).to be(false)
    end

    it 'evaluates the service rows of the whole report' do
      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      expect(described_class.for_report(user: user, report: report).allowed?).to be(false)

      grant_project_access(user, hiv_role, [project_b], mode: :acl)
      expect(described_class.for_report(user: user, report: report).allowed?).to be(true)
    end

    it 'denies a service with no matching enrollment' do
      grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)
      services = services_on(project_a)
      services.update_all(enrollment_id: missing_enrollment_id)

      expect(report.hopwa_caper_services.where(enrollment_id: missing_enrollment_id).count).to be >= 1
      expect(access_for(enrollments: HopwaCaper::Enrollment.none, services: report.hopwa_caper_services.where(enrollment_id: missing_enrollment_id)).allowed?).to be(false)
    end
  end

  context 'with no rows' do
    let(:report) { create_report([project_a]) }

    it 'allows when both relations are empty' do
      access = described_class.new(user: user, enrollments: HopwaCaper::Enrollment.none, services: HopwaCaper::Service.none)

      expect(access.allowed?).to be(true)
    end
  end

  describe '.for_report' do
    let(:report) { create_report([project_a]) }

    before do
      enroll(client_a, project_a)
      run_report(report)
    end

    it 'evaluates every enrollment and service in the report' do
      expect(described_class.for_report(user: user, report: report).allowed?).to be(false)

      grant_project_access(user, hiv_role, [project_a], mode: :acl)
      expect(described_class.for_report(user: user, report: report).allowed?).to be(true)
    end
  end
end
