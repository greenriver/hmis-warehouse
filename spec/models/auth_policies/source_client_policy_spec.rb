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

  shared_examples 'permission checks' do |role_present|
    it 'handles basic permissions appropriately' do
      [
        [:can_view_name?, true],
        [:can_view_photo?, true],
        [:can_view_full_dob?, true],
        [:can_view_full_ssn?, false],
        [:can_view_hiv_status?, false],
      ].each do |method, expected|
        expected = role_present ? expected : false
        actual = policy.send(method)
        expect(actual).to eq(expected), "#{method}: #{actual} != #{expected}"
      end
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
        # expect(policy.can_search?).to be true
      end

      context 'without obeys consent' do
        before(:each) do
          data_source.update!(obey_consent: false)
        end

        it 'grants no ROI permissions' do
          expect(policy.can_view?).to be false
          # expect(policy.can_search?).to be false
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
        # expect(policy.can_search?).to be false
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
    let(:policy) { described_class.new(user: user, resource: client) }

    context 'with project access' do
      before { access_group.add_viewable(project) }
      include_examples 'permission checks', true
      include_examples 'roi checks'
    end

    context 'without project access' do
      include_examples 'permission checks', false
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:policy) { described_class.new(user: user, resource: client) }

    context 'with collection access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = create(:collection)
        create(:access_control, role: role, collection: collection, user_group: user_group)
        collection.set_viewables({ projects: [project.id] })
      end

      include_examples 'permission checks', true
      include_examples 'roi checks'
    end

    context 'without collection access' do
      include_examples 'permission checks', false
    end

    context 'with system collection access' do
      before do
        user_group = create(:user_group)
        user_group.add(user)
        collection = Collection.system_collection(:data_sources)
        create(:access_control, role: role, collection: collection, user_group: user_group)
      end

      include_examples 'permission checks', true
    end
  end
end
