###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisProjectPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:user) do
    u = create(:hmis_user)
    u.hmis_data_source_id = data_source.id
    u
  end
  let(:policy) { user.policy_for(project, policy_type: :hmis_project) }

  shared_examples 'permission checks with access' do
    it 'grants configured permissions' do
      expect(policy.can_view?).to be true
      expect(policy.can_edit?).to be true
    end

    it 'denies unconfigured permissions' do
      expect(policy.can_destroy?).to be false
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all permissions when user lacks access' do
      expect(policy.can_view?).to be false
      expect(policy.can_edit?).to be false
      expect(policy.can_destroy?).to be false
    end
  end

  context 'with direct project access' do
    before do
      create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
    end
    include_examples 'permission checks with access'
  end

  context 'with organization access' do
    before do
      create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details])
    end
    include_examples 'permission checks with access'
  end

  context 'with data source access' do
    before do
      create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
    end
    include_examples 'permission checks with access'
  end

  context 'with project group access' do
    let(:project_group) do
      group = create(:hmis_project_group)
      project.project_groups << group
      project.save!
      group
    end

    before do
      create_access_control(user, project_group, with_permission: [:can_view_project, :can_edit_project_details])
    end

    include_examples 'permission checks with access'
  end

  context 'without any access' do
    include_examples 'permission checks without access'
  end

  context 'when project belongs to a different data source' do
    let(:other_data_source) { create(:hmis_data_source) }
    let(:other_project) { create(:hmis_hud_project, data_source: other_data_source) }
    let(:policy) { user.policy_for(other_project, policy_type: :hmis_project) }

    before do
      # Grant permission to the project in the other data source
      create_access_control(user, other_project, with_permission: [:can_view_project, :can_edit_project_details])
    end

    it 'denies all permissions even if permission is granted via access control' do
      expect(policy.can_view?).to be false
      expect(policy.can_edit?).to be false
    end
  end
end
