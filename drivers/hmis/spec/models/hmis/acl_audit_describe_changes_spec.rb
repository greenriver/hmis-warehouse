###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS ACL describe_changes', type: :model do
  def make_version(item, event:, changes:)
    create(
      :gr_paper_trail_version,
      item_type: item.class.sti_name,
      item_id: item.id,
      event: event,
      object_changes: changes.to_yaml,
    )
  end

  describe Hmis::UserGroupMember do
    let!(:user_group) { create(:hmis_user_group) }
    let!(:hmis_user) { create(:hmis_user) }
    let!(:member) { Hmis::UserGroupMember.create!(user_group: user_group, user: hmis_user) }

    it 'describes a create as adding a user' do
      version = make_version(member, event: 'create', changes: { 'user_id' => [nil, hmis_user.id] })
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Added user').and include(hmis_user.name)
    end

    it 'describes a destroy as removing a user' do
      version = make_version(member, event: 'destroy', changes: { 'user_id' => [hmis_user.id, nil] })
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Removed user').and include(hmis_user.name)
    end
  end

  describe Hmis::UserAccessControl do
    let!(:access_control) { create(:hmis_access_control) }
    let!(:hmis_user) { create(:hmis_user) }
    let!(:uac) { Hmis::UserAccessControl.create!(access_control: access_control, user: hmis_user) }

    it 'describes a create as directly assigning a user' do
      version = make_version(uac, event: 'create', changes: { 'user_id' => [nil, hmis_user.id] })
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Directly assigned user').and include(hmis_user.name)
    end

    it 'describes a destroy as removing a direct assignment' do
      version = make_version(uac, event: 'destroy', changes: { 'user_id' => [hmis_user.id, nil] })
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Removed direct user assignment').and include(hmis_user.name)
    end
  end

  describe Hmis::AccessControl do
    let!(:role1) { create(:hmis_role, name: 'Read Only') }
    let!(:role2) { create(:hmis_role, name: 'Full Access') }
    let!(:access_control) { create(:hmis_access_control, role: role1) }

    it 'describes a create event' do
      version = make_version(access_control, event: 'create', changes: { 'role_id' => [nil, role1.id] })
      result = described_class.describe_changes(version, {})
      expect(result).to eq(['Created access control'])
    end

    it 'describes a destroy event' do
      version = make_version(access_control, event: 'destroy', changes: { 'role_id' => [role1.id, nil] })
      result = described_class.describe_changes(version, {})
      expect(result).to eq(['Deleted access control'])
    end

    it 'describes a role change by name' do
      version = make_version(access_control, event: 'update', changes: { 'role_id' => [role1.id, role2.id] })
      result = described_class.describe_changes(version, { 'role_id' => [role1.id, role2.id] })
      expect(result.first).to include('Role').and include('Read Only').and include('Full Access')
    end

    it 'filters excluded fields' do
      version = make_version(access_control, event: 'update', changes: { 'updated_at' => [1.day.ago, Time.current] })
      result = described_class.describe_changes(version, { 'updated_at' => [1.day.ago, Time.current] }, ['updated_at'])
      expect(result).to eq(['Updated access control'])
    end
  end

  describe Hmis::GroupViewableEntity do
    let!(:access_group) { create(:hmis_access_group) }
    let!(:project) { create(:hmis_hud_project) }
    let!(:gve) { create(:hmis_group_viewable_entity, collection: access_group, entity: project) }

    it 'describes a create as adding an entity' do
      version = create(
        :grda_warehouse_version,
        item_type: 'Hmis::GroupViewableEntity',
        item_id: gve.id,
        event: 'create',
        object_changes: {
          'entity_id' => [nil, project.id],
          'entity_type' => [nil, 'Hmis::Hud::Project'],
          'collection_id' => [nil, access_group.id],
        }.to_yaml,
      )
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Added')
    end

    it 'describes a destroy as removing an entity' do
      version = create(
        :grda_warehouse_version,
        item_type: 'Hmis::GroupViewableEntity',
        item_id: gve.id,
        event: 'destroy',
        object_changes: {
          'entity_id' => [project.id, nil],
          'entity_type' => ['Hmis::Hud::Project', nil],
          'collection_id' => [access_group.id, nil],
        }.to_yaml,
      )
      result = described_class.describe_changes(version, {})
      expect(result.first).to include('Removed')
    end
  end
end
