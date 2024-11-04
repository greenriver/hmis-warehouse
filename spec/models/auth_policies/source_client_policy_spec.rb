require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::SourceClientPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:project) { create :grda_warehouse_hud_project, organization: organization }
  let(:client) do
    client = create(:hud_client, data_source: data_source)
    create :hud_enrollment, client: client, data_source: data_source, project: project
    client
  end

  # Permissions that will be granted through the role
  let(:permissions) do
    {
      can_view_client_name: true,
      can_view_client_photo: true,
      can_view_full_dob: true,
      can_view_full_ssn: false,
      can_view_hiv_status: nil,
    }
  end

  let(:role) { create(:role, **permissions.compact_blank) }

  shared_examples 'pii permission checks with access' do
    it 'grants configured PII permissions' do
      # These permissions are granted in our test role
      expect(policy.can_view_name?).to be true
      expect(policy.can_view_photo?).to be true
      expect(policy.can_view_full_dob?).to be true
    end

    it 'denies unconfigured PII permissions' do
      # These permissions aren't granted in our test role
      expect(policy.can_view_full_ssn?).to be false
      expect(policy.can_view_hiv_status?).to be false
    end
  end

  shared_examples 'pii permission checks without access' do
    it 'denies all PII permissions when user lacks access' do
      expect(policy.can_view_name?).to be false
      expect(policy.can_view_photo?).to be false
      expect(policy.can_view_full_dob?).to be false
      expect(policy.can_view_full_ssn?).to be false
      expect(policy.can_view_hiv_status?).to be false
    end
  end

  shared_examples 'roi checks' do
    context 'with ROI authorizations' do
      before(:each) do
        create(:warehouse_client, source: client, data_source: data_source)
        create(:client_roi_authorization, destination_client: client.destination_client)
        role.update!(can_search_clients_with_roi: true, can_view_client_enrollments_with_roi: true)
      end

      it 'grants view and search permissions through ROI' do
        expect(policy.can_view?).to be true
      end

      context 'without obeys consent' do
        before(:each) do
          data_source.update!(obey_consent: false)
        end

        it 'grants no ROI permissions' do
          expect(policy.can_view?).to be false
        end
      end
    end

    context 'without ROI authorizations' do
      before(:each) do
        create(:warehouse_client, source: client, data_source: data_source)
        role.update!(can_search_clients_with_roi: true, can_view_client_enrollments_with_roi: true)
      end

      it 'grants no ROI permissions' do
        expect(policy.can_view?).to be false
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
    let(:policy) { user.policy_for(client) }

    context 'with project access' do
      before { access_group.add_viewable(project) }
      include_examples 'pii permission checks with access'
      include_examples 'roi checks'
    end

    context 'without project access' do
      include_examples 'pii permission checks without access'
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { user.policy_for(client) }
    let(:collection) { create :collection }
    before do
      user_group = create(:user_group)
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    context 'with collection access' do
      before do
        collection.set_viewables({ projects: [project.id] })
      end

      include_examples 'pii permission checks with access'
      include_examples 'roi checks'
    end

    context 'without collection access' do
      include_examples 'pii permission checks without access'
    end

    context 'with system collection access' do
      let(:collection) { Collection.system_collection(:data_sources) }
      before do
        user_group = create(:user_group)
        user_group.add(user)
        create(:access_control, role: role, collection: collection, user_group: user_group)
      end

      include_examples 'pii permission checks with access'
    end
  end
end
