###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The data source index decides which delete buttons to show with the `deletable_by` scope
# (one query for the page), while single-record pages and controller actions ask
# DataSourcePolicy. These examples pin the two to the same answer for each kind of grant, so
# they can't drift apart.
RSpec.describe GrdaWarehouse::AuthPolicies::DataSourcePolicy, type: :model do
  let!(:data_source) { create :source_data_source }
  let!(:organization) { create :hud_organization, data_source_id: data_source.id }
  let!(:project) do
    create :hud_project,
           data_source_id: data_source.id,
           OrganizationID: organization.OrganizationID
  end
  let!(:other_data_source) { create :source_data_source }

  let(:edit_and_delete_permissions) do
    {
      can_view_projects: true,
      can_edit_data_sources: true,
      can_delete_data_sources: true,
    }
  end
  let(:edit_only_permissions) do
    {
      can_view_projects: true,
      can_edit_data_sources: true,
    }
  end
  let(:view_only_permissions) do
    { can_view_projects: true }
  end

  # User memoizes permissions and the policy context, so read the answers from a fresh instance.
  def answers_for(user)
    fresh_user = User.find(user.id)
    policy = fresh_user.policy_for(data_source)
    {
      editable_by: GrdaWarehouse::DataSource.editable_by(fresh_user).exists?(id: data_source.id),
      can_edit: policy.can_edit?,
      deletable_by: GrdaWarehouse::DataSource.deletable_by(fresh_user).exists?(id: data_source.id),
      can_delete: policy.can_delete?,
    }
  end

  def viewable?(user)
    fresh_user = User.find(user.id)
    GrdaWarehouse::DataSource.viewable_by(fresh_user).exists?(id: data_source.id)
  end

  # DataSourcesController#destroy loads the record through viewable_by before asking the policy,
  # so a deletable data source that isn't viewable would show a Delete button that 404s.
  def expect_answers(user, edit:, delete:)
    expect(answers_for(user)).to eq(
      editable_by: edit,
      can_edit: edit,
      deletable_by: delete,
      can_delete: delete,
    )
    expect(viewable?(user)).to be(true) if delete
  end

  context 'with an ACL user' do
    let(:user) { create :acl_user }
    let(:collection) { create :collection }

    def grant(permissions, entities)
      role = create(:role, **permissions)
      collection.set_viewables(entities)
      setup_access_control(user, role, collection)
    end

    it 'allows edit and delete from a direct data source grant whose role has both' do
      grant(edit_and_delete_permissions, { data_sources: [data_source.id] })
      expect_answers(user, edit: true, delete: true)
    end

    it 'allows edit but not delete from a direct data source grant whose role has edit only' do
      grant(edit_only_permissions, { data_sources: [data_source.id] })
      expect_answers(user, edit: true, delete: false)
    end

    it 'allows neither when the data source is visible only through one of its organizations' do
      grant(edit_and_delete_permissions, { organizations: [organization.id] })
      expect(viewable?(user)).to be true
      expect_answers(user, edit: false, delete: false)
    end

    it 'allows neither when the data source is visible only through one of its projects' do
      grant(edit_and_delete_permissions, { projects: [project.id] })
      expect(viewable?(user)).to be true
      expect_answers(user, edit: false, delete: false)
    end

    it 'allows neither from a grant on a different data source' do
      grant(edit_and_delete_permissions, { data_sources: [other_data_source.id] })
      expect_answers(user, edit: false, delete: false)
    end

    it 'allows edit and delete from a grant on the system "All Data Sources" collection' do
      role = create(:role, **edit_and_delete_permissions)
      setup_access_control(user, role, Collection.system_collection(:data_sources))
      expect_answers(user, edit: true, delete: true)
    end
  end

  context 'with a legacy user' do
    let(:user) { create :user }
    let(:access_group) { create :access_group }

    def grant(permissions, entity)
      create(:role, **permissions).add(user)
      access_group.add(user)
      access_group.add_viewable(entity)
    end

    it 'allows edit and delete from a direct data source grant whose role has both' do
      grant(edit_and_delete_permissions, data_source)
      expect_answers(user, edit: true, delete: true)
    end

    it 'allows edit but not delete from a direct data source grant whose role has edit only' do
      grant(edit_only_permissions, data_source)
      expect_answers(user, edit: true, delete: false)
    end

    it 'allows neither when the data source is visible only through one of its organizations' do
      grant(edit_and_delete_permissions, organization)
      expect(viewable?(user)).to be true
      expect_answers(user, edit: false, delete: false)
    end

    it 'allows neither when the data source is visible only through one of its projects' do
      grant(edit_and_delete_permissions, project)
      expect(viewable?(user)).to be true
      expect_answers(user, edit: false, delete: false)
    end

    it 'allows neither from a grant on a different data source' do
      grant(edit_and_delete_permissions, other_data_source)
      expect_answers(user, edit: false, delete: false)
    end

    # The policy adds the system group to every data source lookup
    # (UserLegacyContext#permissions_for_access_group_ids), while directly_viewable_by matches the
    # group's GroupViewableEntity rows. Those rows hold every data source because
    # AccessGroup.maintain_system_groups runs when a data source is created.
    context 'in the system "All Data Sources" access group' do
      let(:system_group) { AccessGroup.system_group(:data_sources) }

      before { system_group.add(user) }

      it 'allows edit and delete when the role has both' do
        create(:role, **edit_and_delete_permissions).add(user)
        expect_answers(user, edit: true, delete: true)
      end

      it 'allows edit but not delete when the role has edit only' do
        create(:role, **edit_only_permissions).add(user)
        expect_answers(user, edit: true, delete: false)
      end
    end

    # Known, intended difference. For legacy users, editable_by is directly_viewable_by and
    # doesn't check can_edit_data_sources; DataSourcesController used to make up for that with a
    # global require_can_edit_data_sources!. The policy requires the flag, so it is stricter.
    # deletable_by checks its flag, so the two agree on delete.
    it 'is stricter than editable_by for a direct grant whose role lacks can_edit_data_sources' do
      grant(view_only_permissions, data_source)
      expect(answers_for(user)).to eq(
        editable_by: true,
        can_edit: false,
        deletable_by: false,
        can_delete: false,
      )
    end
  end
end
