
require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ProjectPiiPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }

  let(:full_access_role) do
    create(:role,
      can_view_client_name: true,
      can_view_client_photo: true,
      can_view_full_dob: true,
      can_view_full_ssn: true,
      can_view_hiv_status: true
    )
  end

  let(:limited_access_role) do
    create(:role,
      can_view_client_name: true,
      can_view_client_photo: true,
      can_view_full_dob: true
    )
  end

  let(:no_access_role) do
    create(:role)
  end

  shared_examples 'pii permission checks' do |role_present|
    context 'with full access role' do
      let(:role) { full_access_role }

      it 'grants all PII permissions' do
        expect(policy.can_view_name?).to eq(role_present)
        expect(policy.can_view_photo?).to eq(role_present)
        expect(policy.can_view_full_dob?).to eq(role_present)
        expect(policy.can_view_full_ssn?).to eq(role_present)
        expect(policy.can_view_hiv_status?).to eq(role_present)
      end
    end

    context 'with limited access role' do
      let(:role) { limited_access_role }

      it 'grants only specified permissions' do
        expect(policy.can_view_name?).to eq(role_present)
        expect(policy.can_view_photo?).to eq(role_present)
        expect(policy.can_view_full_dob?).to eq(role_present)
        expect(policy.can_view_full_ssn?).to be false
        expect(policy.can_view_hiv_status?).to be false
      end
    end

    context 'with no access role' do
      let(:role) { no_access_role }

      it 'denies all PII permissions' do
        expect(policy.can_view_name?).to be false
        expect(policy.can_view_photo?).to be false
        expect(policy.can_view_full_dob?).to be false
        expect(policy.can_view_full_ssn?).to be false
        expect(policy.can_view_hiv_status?).to be false
      end
    end
  end

  context 'with legacy user permissions' do
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
      include_examples 'pii permission checks', true
    end

    context 'with system group access' do
      before do
        system_group = AccessGroup.system_groups[:data_sources]
        system_group.add(user)
      end
      include_examples 'pii permission checks', true
    end

    context 'without any access' do
      include_examples 'pii permission checks', false
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
      include_examples 'pii permission checks', true
    end

    context 'with system collection access' do
      before do
        collection = Collection.system_collection(:data_sources)
        create(:access_control, role: role, collection: collection, user_group: user_group)
      end
      include_examples 'pii permission checks', true
    end

    context 'without any access' do
      include_examples 'pii permission checks', false
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
        expect(policy.can_view_full_ssn?).to be true
        expect(policy.can_view_hiv_status?).to be true
      end
    end
  end
end
