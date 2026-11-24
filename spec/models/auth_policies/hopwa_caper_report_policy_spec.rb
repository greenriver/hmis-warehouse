###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../drivers/hopwa_caper/spec/models/generators/fy2026/hopwa_caper_shared_context'

RSpec.describe GrdaWarehouse::AuthPolicies::HopwaCaperReportPolicy, type: :model do
  include_context 'HOPWA CAPER shared context'

  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project_a) { create_hopwa_project(funder: tbra_funder) }
  let(:project_b) { create_hopwa_project(funder: tbra_funder) }
  let(:hiv_role) { create(:role, can_view_hiv_status: true) }
  let(:client_a) { create_client_with_warehouse_link(first_name: 'Ann', last_name: 'Able') }
  let(:client_b) { create_client_with_warehouse_link(first_name: 'Bo', last_name: 'Baker') }
  let(:report) { create_report([project_a, project_b]) }
  let(:hopwa_url) { 'hud_reports/hopwa_capers' }

  def enroll(client, project)
    create_hiv_positive_enrollment(
      client: client,
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
  end

  def policy = user.policy_for(report, policy_class: described_class)

  context 'with a report run' do
    before do
      enroll(client_a, project_a)
      enroll(client_b, project_b)
      run_report(report)
    end

    describe '#can_view_drilldowns?' do
      it 'allows when the report is granted and every project grants HIV status' do
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)

        expect(policy.can_view_drilldowns?).to be(true)
      end

      it 'denies when one project lacks HIV status' do
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a], mode: :acl)

        expect(report.hopwa_caper_enrollments.pluck(:project_id).uniq).to contain_exactly(project_a.id, project_b.id)
        expect(policy.can_view?).to be(true)
        expect(policy.can_view_drilldowns?).to be(false)
      end

      it 'denies when the HOPWA CAPER report is not granted, even with HIV status on every project' do
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)

        expect(HopwaCaper::HivDrilldownAccess.for_report(user: user, report: report).allowed?).to be(true)
        expect(policy.can_view_drilldowns?).to be(false)
      end

      it 'denies another user\'s run without can_view_all_hud_reports' do
        report.update!(user_id: create(:acl_user).id)
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)

        expect(HopwaCaper::HivDrilldownAccess.for_report(user: user, report: report).allowed?).to be(true)
        expect(policy.can_view_definition?).to be(true)
        expect(policy.can_view_drilldowns?).to be(false)
      end

      it 'allows another user\'s run with can_view_all_hud_reports' do
        report.update!(user_id: create(:acl_user).id)
        grant_hud_report(user, hopwa_url, role: create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true))
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)

        expect(policy.can_view_drilldowns?).to be(true)
      end

      it 'answers a repeat call without querying the database' do
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)
        report_policy = policy
        first_answer = nil

        expect(count_database_queries { first_answer = report_policy.can_view_drilldowns? }).to be > 0
        expect(first_answer).to be(true)
        expect(count_database_queries { expect(report_policy.can_view_drilldowns?).to be(true) }).to eq(0)
      end

      context 'with a legacy user' do
        let(:legacy_user) { create(:user) }
        let(:legacy_policy) { legacy_user.policy_for(report, policy_class: described_class) }

        before { report.update!(user_id: legacy_user.id) }

        it 'allows when the legacy role grants HIV status on every project' do
          grant_hud_report(legacy_user, hopwa_url)
          grant_project_access(legacy_user, hiv_role, [project_a, project_b], mode: :legacy)

          expect(legacy_policy.can_view_drilldowns?).to be(true)
        end

        it 'denies when the legacy role grants other client data but not HIV status' do
          grant_hud_report(legacy_user, hopwa_url)
          no_hiv_role = create(:role, can_view_clients: true, can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true, can_view_hiv_status: false)
          grant_project_access(legacy_user, no_hiv_role, [project_a, project_b], mode: :legacy)

          expect(legacy_policy.can_view?).to be(true)
          expect(legacy_policy.can_view_drilldowns?).to be(false)
        end
      end
    end

    describe '#can_view_cell?' do
      let(:project_a_rows) { report.hopwa_caper_enrollments.where(project_id: project_a.id) }
      let(:no_services) { HopwaCaper::Service.none }

      it 'allows rows from projects with HIV status and denies rows that include another project' do
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a], mode: :acl)

        expect(policy.can_view_cell?(enrollments: project_a_rows, services: no_services, mode: :browse)).to be(true)
        expect(policy.can_view_cell?(enrollments: report.hopwa_caper_enrollments, services: no_services, mode: :browse)).to be(false)
      end

      it 'denies downloads when detail downloads exclude PII' do
        grant_hud_report(user, hopwa_url)
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)
        allow(GrdaWarehouse::Config).to receive(:get).and_call_original
        allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)

        expect(policy.can_view_cell?(enrollments: project_a_rows, services: no_services, mode: :browse)).to be(true)
        expect(policy.can_view_cell?(enrollments: project_a_rows, services: no_services, mode: :download)).to be(false)
      end

      it 'denies when the HOPWA CAPER report is not granted' do
        grant_project_access(user, hiv_role, [project_a, project_b], mode: :acl)

        expect(HopwaCaper::HivDrilldownAccess.new(user: user, enrollments: project_a_rows, services: no_services, mode: :browse).allowed?).to be(true)
        expect(policy.can_view_cell?(enrollments: project_a_rows, services: no_services, mode: :browse)).to be(false)
      end
    end
  end

  describe 'policy lookup' do
    it 'returns the HOPWA policy only when requested and reuses it' do
      report.update!(question_names: [])
      hopwa_policy = user.policy_for(report, policy_class: described_class)

      expect(user.policy_for(report)).to be_instance_of(GrdaWarehouse::AuthPolicies::HudReportPolicy)
      expect(hopwa_policy).to be_instance_of(described_class)
      expect(user.policy_for(report, policy_class: described_class)).to equal(hopwa_policy)
    end

    it 'rejects a run that is not a HOPWA CAPER' do
      apr_run = create(:hud_reports_report_instance, user: user, report_name: HudApr::Generators::Apr::Fy2026::Generator.title)

      expect { user.policy_for(apr_run, policy_class: described_class) }.to raise_error(ArgumentError, /HOPWA CAPER/)
    end
  end
end
