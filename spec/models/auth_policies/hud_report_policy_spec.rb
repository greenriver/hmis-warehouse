# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  context 'with invalid resource type' do
    let(:user) { create(:user) }

    it 'raises an argument error' do
      expect { user.policy_for('not a report instance', policy_class: GrdaWarehouse::AuthPolicies::HudReportPolicy) }.to raise_error(ArgumentError)
    end
  end
end
