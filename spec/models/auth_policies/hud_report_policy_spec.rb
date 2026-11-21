###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::HudReportPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }
  let(:report_instance) { create :hud_reports_report_instance, project_ids: [project.id] }
  let(:access_group) { create(:access_group) }
  shared_examples 'checks permissions' do
    let(:policy) { user.policy_for(report_instance) }

    context 'with both required permissions' do
      let(:role) { create(:role, can_view_all_hud_reports: true, can_manage_config: true) }

      it 'allows viewing checkpoints' do
        expect(policy.can_view_checkpoints?).to be true
      end
    end

    context 'with only can_view_all_hud_reports' do
      let(:role) { create(:role, can_view_all_hud_reports: true) }

      it 'denies viewing checkpoints' do
        expect(policy.can_view_checkpoints?).to be false
      end
    end

    context 'with only can_manage_config' do
      let(:role) { create(:role, can_manage_config: true) }

      it 'denies viewing checkpoints' do
        expect(policy.can_view_checkpoints?).to be false
      end
    end

    context 'with no permissions' do
      let(:role) { create(:role) }

      it 'denies viewing checkpoints' do
        expect(policy.can_view_checkpoints?).to be false
      end
    end
  end

  context 'with legacy user' do
    let(:user) do
      user = create(:user)
      role.add(user)

      ds_group = AccessGroup.system_groups[:data_sources] || create(:access_group, name: 'All Data Sources', system: ['Entities'])
      ds_group.add(user)

      access_group.add(user)
      access_group.add_viewable(project)
      user
    end

    include_examples 'checks permissions'
  end

  context 'with acl user' do
    let(:user) { create(:acl_user) }
    let(:user_group) { create(:user_group) }
    let(:ds_collection) { Collection.system_collection(:data_sources) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: ds_collection, user_group: user_group)
    end

    include_examples 'checks permissions'
  end

  describe '#can_view?' do
    let(:apr_title) { HudApr::Generators::Apr::Fy2026::Generator.title }
    let(:all_runs_role) { create(:role, can_view_assigned_reports: true, can_view_all_hud_reports: true) }
    let(:own_run) { create(:hud_reports_report_instance, user: user, report_name: apr_title) }
    let(:other_run) { create(:hud_reports_report_instance, user: create(:user), report_name: apr_title) }

    shared_examples 'HUD report run access' do
      it 'allows the user\'s own run of a granted report' do
        grant_hud_report(user, 'hud_reports/aprs')

        expect(user.policy_for(own_run).can_view?).to be(true)
      end

      it 'denies another user\'s run without can_view_all_hud_reports' do
        grant_hud_report(user, 'hud_reports/aprs')
        policy = user.policy_for(other_run)

        expect(user.policy_for(own_run).can_view?).to be(true)
        expect(policy.can_view_definition?).to be(true)
        expect(policy.run_visible?).to be(false)
        expect(policy.can_view?).to be(false)
      end

      it 'allows another user\'s run with can_view_all_hud_reports' do
        grant_hud_report(user, 'hud_reports/aprs', role: all_runs_role)

        expect(user.policy_for(other_run).can_view?).to be(true)
      end

      it 'denies the user\'s own run when only another report is granted' do
        grant_hud_report(user, 'hud_reports/spms', role: all_runs_role)
        spm_run = create(:hud_reports_report_instance, user: user, report_name: HudSpmReport::Generators::Fy2026::Generator.title)
        policy = user.policy_for(own_run)

        expect(user.policy_for(spm_run).can_view?).to be(true)
        expect(policy.run_visible?).to be(true)
        expect(policy.can_view_definition?).to be(false)
        expect(policy.can_view?).to be(false)
      end

      it 'denies a run whose report name matches no HUD generator' do
        grant_hud_report(user, 'hud_reports/aprs', role: all_runs_role)
        unknown_run = create(:hud_reports_report_instance, user: user, report_name: 'Not a HUD report')

        expect(user.policy_for(own_run).can_view?).to be(true)
        expect(user.policy_for(unknown_run).can_view?).to be(false)
      end

      it 'allows the owner\'s retired-year run under the parent report' do
        grant_hud_report(user, 'hud_reports/lsas')
        retired_run = create(:hud_reports_report_instance, user: user, report_name: HudLsa::Generators::Fy2024::Lsa.title)

        expect(user.policy_for(retired_run).can_view?).to be(true)
        expect(user.policy_for(own_run).can_view?).to be(false)
      end
    end

    context 'with an acl user' do
      let(:user) { create(:acl_user) }

      include_examples 'HUD report run access'
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }

      include_examples 'HUD report run access'
    end
  end

  context 'with invalid resource type' do
    let(:user) { create(:user) }

    it 'raises an argument error' do
      expect { user.policy_for('not a report instance', policy_class: GrdaWarehouse::AuthPolicies::HudReportPolicy) }.to raise_error(ArgumentError)
    end
  end
end
