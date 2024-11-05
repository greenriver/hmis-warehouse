require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ProjectPiiPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }

  let(:full_access_role) do
    create(:role,
           can_view_client_name: true,
           can_view_client_photo: true,
           can_view_full_dob: true,
           can_view_full_ssn: false,
           can_view_hiv_status: true)
  end

  let(:limited_access_role) do
    create(:role,
           can_view_client_name: true,
           can_view_client_photo: true,
           can_view_full_dob: true)
  end

  let(:no_access_role) do
    create(:role)
  end

  shared_examples 'pii permission checks with access' do |_has_access|
    it 'grants configured PII permissions' do
      # These permissions are granted in our test role
      expect(policy.can_view_name?).to be true
      expect(policy.can_view_photo?).to be true
      expect(policy.can_view_full_dob?).to be true
      expect(policy.can_view_hiv_status?).to be true
    end

    it 'denies unconfigured PII permissions' do
      # These permissions aren't granted in our test role
      expect(policy.can_view_full_ssn?).to be false
    end
  end

  shared_examples 'pii permission checks without access' do |_has_access|
    it 'denies all PII permissions when user lacks access' do
      expect(policy.can_view_name?).to be false
      expect(policy.can_view_photo?).to be false
      expect(policy.can_view_full_dob?).to be false
      expect(policy.can_view_full_ssn?).to be false
      expect(policy.can_view_hiv_status?).to be false
    end
  end

  context 'with legacy user permissions' do
    let(:role) { full_access_role }
    let(:access_group) { create(:access_group) }
    let(:user) do
      user = create(:user)
      role.add(user)
      access_group.add(user)
      user
    end
    let(:policy) { described_class.new(resource: project.id, context: user.policy_context) }

    context 'with project access' do
      before { access_group.add_viewable(project) }
      include_examples 'pii permission checks with access'
    end

    context 'with system group access' do
      before do
        system_group = AccessGroup.system_groups[:data_sources]
        system_group.add(user)
      end
      include_examples 'pii permission checks with access'
    end

    context 'without any access' do
      include_examples 'pii permission checks without access'
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:user_group) { create(:user_group) }
    let(:collection) { create(:collection) }
    let(:role) { full_access_role }
    let(:policy) { described_class.new(resource: project.id, context: user.policy_context) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    context 'with direct project access' do
      before { collection.set_viewables({ projects: [project.id] }) }
      include_examples 'pii permission checks with access'
    end

    context 'with system collection access' do
      let(:collection) { Collection.system_collection(:data_sources) }
      before do
        create(:access_control, role: role, collection: collection, user_group: user_group)
      end
      include_examples 'pii permission checks with access'
    end

    context 'without any access' do
      include_examples 'pii permission checks without access'
    end

    context 'with multiple roles' do
      let(:collection2) { create(:collection) }

      before do
        collection.set_viewables({ projects: [project.id] })
        collection2.set_viewables({ projects: [project.id] })
        create(:access_control, role: full_access_role, collection: collection, user_group: user_group)
        create(:access_control, role: limited_access_role, collection: collection2, user_group: user_group)
      end

      it 'combines permissions from multiple roles' do
        expect(policy.can_view_name?).to be true
        expect(policy.can_view_photo?).to be true
        expect(policy.can_view_full_dob?).to be true
        expect(policy.can_view_full_ssn?).to be false
        expect(policy.can_view_hiv_status?).to be true
      end
    end
  end
end
