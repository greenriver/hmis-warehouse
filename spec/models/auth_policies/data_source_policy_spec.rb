# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::DataSourcePolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  # Default role for shared examples
  let(:role) { no_access_role }

  let(:full_access_role) do
    create(:role,
           can_edit_data_sources: true,
           can_upload_hud_zips: true)
  end

  let(:edit_only_role) do
    create(:role,
           can_edit_data_sources: true)
  end

  let(:upload_only_role) do
    create(:role,
           can_upload_hud_zips: true)
  end

  let(:no_access_role) do
    create(:role)
  end

  shared_examples 'permission checks with access' do
    context 'with full access role' do
      let(:role) { full_access_role }

      it 'grants both edit and raw HMIS data access' do
        expect(policy.can_edit?).to be true
        expect(policy.can_see_raw_hmis_data?).to be true
      end
    end

    context 'with edit-only role' do
      let(:role) { edit_only_role }

      it 'grants edit but denies raw HMIS data access' do
        expect(policy.can_edit?).to be true
        expect(policy.can_see_raw_hmis_data?).to be false
      end
    end

    context 'with upload-only role' do
      let(:role) { upload_only_role }

      it 'denies both edit and raw HMIS data access' do
        expect(policy.can_edit?).to be false
        expect(policy.can_see_raw_hmis_data?).to be false
      end
    end

    context 'with no permissions role' do
      let(:role) { no_access_role }

      it 'denies all access' do
        expect(policy.can_edit?).to be false
        expect(policy.can_see_raw_hmis_data?).to be false
      end
    end
  end

  shared_examples 'permission checks without access' do
    it 'denies all access when user lacks resource access' do
      [full_access_role, edit_only_role, upload_only_role, no_access_role].each do |test_role|
        expect(policy.can_edit?).to be(false),
                                    "Expected edit access to be denied with #{test_role.class}"
        expect(policy.can_see_raw_hmis_data?).to be(false),
                                                 "Expected raw HMIS access to be denied with #{test_role.class}"
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
    let(:policy) { user.policy_for(data_source) }

    context 'with direct data source access' do
      before { access_group.add_viewable(data_source) }
      include_examples 'permission checks with access'
    end

    context 'with system group access' do
      before do
        system_group = AccessGroup.system_groups[:data_sources]
        system_group.add(user)
      end
      include_examples 'permission checks with access'
    end

    context 'without any access' do
      include_examples 'permission checks without access'
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { user.policy_for(data_source) }
    let(:user_group) { create(:user_group) }
    let(:collection) { create(:collection) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    context 'with direct data source access' do
      before { collection.set_viewables({ data_sources: [data_source.id] }) }
      include_examples 'permission checks with access'
    end

    context 'with system collection access' do
      let(:collection) { Collection.system_collection(:data_sources) }
      include_examples 'permission checks with access'
    end

    context 'without any access' do
      include_examples 'permission checks without access'
    end
  end

  context 'with invalid resource type' do
    let(:user) { create(:user) }
    let(:invalid_resource) { create(:hud_organization) }

    it 'raises an argument error' do
      expect { user.policy_for(invalid_resource) }.to raise_error(ArgumentError)
    end
  end
end
