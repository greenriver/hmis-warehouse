###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::DestinationClientPolicy, type: :model do
  let(:data_source) { create :data_source_fixed_id }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source }
  let(:source_client) { create :hud_client, data_source: data_source }
  let!(:enrollment) { create :hud_enrollment, client: source_client, project: project }

  let!(:destination_data_source) { create :destination_data_source }
  let!(:destination_client) { create :hud_client, data_source_id: destination_data_source.id }
  let!(:warehouse_client) { create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id }

  let(:role) do
    create(:role,
           can_view_clients: true,
           can_view_client_name: true,
           can_view_client_photo: true,
           can_view_full_dob: true,
           can_view_full_ssn: false,
           can_view_hiv_status: false)
  end

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

    context 'with self-referencing warehouse client' do
      before do
        warehouse_client.update!(source_id: destination_client.id)
      end
      it 'denies all PII permissions' do
        expect(policy.can_view_name?).to be false
        expect(policy.can_view_photo?).to be false
        expect(policy.can_view_full_dob?).to be false
        expect(policy.can_view_full_ssn?).to be false
        expect(policy.can_view_hiv_status?).to be false
      end
    end
  end

  shared_examples 'pii permission checks without access' do
    context 'standard PII permissions' do
      it 'denies all PII permissions when user lacks access' do
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
    let(:policy) { user.policy_for(destination_client) }

    context 'with project access' do
      before { access_group.add_viewable(project) }
      include_examples 'pii permission checks with access'
    end

    context 'without project access' do
      include_examples 'pii permission checks without access'
    end
  end

  context 'with user access control permissions' do
    let(:user) { create(:acl_user) }
    let(:user_group) { create(:user_group) }
    let(:policy) { user.policy_for(destination_client) }
    let(:collection) { create(:collection) }

    before do
      user_group.add(user)
      create(:access_control, role: role, collection: collection, user_group: user_group)
    end

    context 'with collection access' do
      before do
        collection.set_viewables({ projects: [project.id] })
      end
      include_examples 'pii permission checks with access'
    end

    context 'without collection access' do
      include_examples 'pii permission checks without access'
    end
  end

  describe 'identity preloading' do
    let(:user) { create(:acl_user) }

    def destination_with_sources(count)
      destination = create(:hud_client, data_source_id: destination_data_source.id)
      create_list(:hud_client, count, data_source: data_source).each do |source|
        create(:warehouse_client, source_id: source.id, destination_id: destination.id)
      end
      destination
    end

    it 'resolves a destination with more source clients than the threshold without raising' do
      destination = destination_with_sources(4)

      expect(user.policy_for(destination).can_view_name?).to eq(false)
    end

    it 'counts each destination resolved without a preload as one miss' do
      destinations = Array.new(4) { destination_with_sources(1) }

      expect { destinations.each { |d| user.policy_for(d).can_view_name? } }.
        to raise_error(GrdaWarehouse::AuthPolicies::PreloadMissTracker::PreloadMissError, /destination_clients/)
    end

    it 'does not count destinations the caller preloaded' do
      destinations = Array.new(4) { destination_with_sources(1) }
      user.policy_context.preload_client_dependencies(destinations.map(&:id))

      expect(destinations.map { |d| user.policy_for(d).can_view_name? }).to eq([false] * 4)
    end
  end

  describe 'client feature permissions' do
    let(:feature_permissions) { { can_view_client_history_calendar: true, can_generate_homeless_verification_pdfs: true } }
    let(:policy) { user.policy_for(destination_client) }

    def feature_results
      [policy.can_view_history_calendar?, policy.can_generate_homeless_verification_pdfs?]
    end

    context 'with user access control permissions' do
      let(:user) { create(:acl_user) }
      let(:client_collection) { create(:collection).tap { |c| c.set_viewables({ projects: [project.id] }) } }

      it 'grants both when a role on the client project has view and both feature permissions' do
        setup_access_control(user, create(:role, can_view_clients: true, **feature_permissions), client_collection)

        expect(feature_results).to eq([true, true])
      end

      it 'grants the history calendar without the PDF permission' do
        setup_access_control(user, create(:role, can_view_clients: true, can_view_client_history_calendar: true), client_collection)

        expect(feature_results).to eq([true, false])
      end

      it 'denies the PDF permission without the history calendar' do
        setup_access_control(user, create(:role, can_view_clients: true, can_generate_homeless_verification_pdfs: true), client_collection)

        expect(feature_results).to eq([false, false])
      end

      it 'denies both when the role lacks can_view_clients' do
        setup_access_control(user, create(:role, **feature_permissions), client_collection)

        expect(feature_results).to eq([false, false])
      end

      it 'denies both when the feature permissions come from a project the client is not enrolled in' do
        other_project = create(:grda_warehouse_hud_project, data_source: data_source)
        other_collection = create(:collection).tap { |c| c.set_viewables({ projects: [other_project.id] }) }
        setup_access_control(user, create(:role, can_view_clients: true), client_collection)
        setup_access_control(user, create(:role, can_view_clients: true, **feature_permissions), other_collection)

        expect(user.can_view_client_history_calendar?).to eq(true)
        expect(user.can_generate_homeless_verification_pdfs?).to eq(true)
        expect(feature_results).to eq([false, false])
      end

      context 'when view access comes from an ROI instead of can_view_clients' do
        before do
          setup_access_control(user, create(:role, can_view_client_enrollments_with_roi: true, **feature_permissions), client_collection)
        end

        it 'grants both when the client has an ROI' do
          create(:client_roi_authorization, destination_client: destination_client)

          expect(feature_results).to eq([true, true])
        end

        it 'denies both when the client has no ROI' do
          expect(feature_results).to eq([false, false])
        end
      end
    end

    context 'with legacy user permissions' do
      let(:access_group) { create(:access_group) }
      let(:user) do
        user = create(:user)
        create(:role, can_view_clients: true, **feature_permissions).add(user)
        access_group.add(user)
        user
      end

      it 'grants both when the access group includes the client project' do
        access_group.add_viewable(project)

        expect(feature_results).to eq([true, true])
      end

      it 'denies both when the access group includes only another project' do
        access_group.add_viewable(create(:grda_warehouse_hud_project, data_source: data_source))

        expect(feature_results).to eq([false, false])
      end
    end
  end

  it 'rejects a source client with an ArgumentError' do
    user = create(:acl_user)
    expect { user.policy_for(source_client, policy_class: described_class) }.to raise_error(ArgumentError, 'Must be a destination client')
  end

  describe '#can_mark_restricted?' do
    let(:marking_role) { create(:role, can_view_clients: true, can_mark_clients_as_restricted: true) }
    let(:viewing_role) { create(:role, can_view_clients: true) }
    let(:other_project) { create :grda_warehouse_hud_project, data_source: data_source }

    def restrict_destination
      Hmis::RestrictedRecord.create!(
        restrictable_id: destination_client.id,
        restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE,
        data_source_id: destination_client.data_source_id,
        created_by: Hmis::User.find(user.id),
      )
    end

    context 'with legacy user permissions' do
      let(:access_group) { create(:access_group) }
      let(:user) { create(:user).tap { |u| access_group.add(u) } }

      it 'is true with the permission and access to the client project' do
        marking_role.add(user)
        access_group.add_viewable(project)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be true
      end

      it 'is still true when the client is restricted' do
        marking_role.add(user)
        access_group.add_viewable(project)
        restrict_destination
        expect(user.policy_for(destination_client).can_mark_restricted?).to be true
      end

      it 'is false with access to the client project but no permission' do
        viewing_role.add(user)
        access_group.add_viewable(project)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be false
      end

      it 'is false with the permission at a project the client is not enrolled in' do
        marking_role.add(user)
        access_group.add_viewable(other_project)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be false
      end
    end

    context 'with user access control permissions' do
      let(:user) { create(:acl_user) }
      let(:user_group) { create(:user_group).tap { |g| g.add(user) } }
      let(:client_collection) { create(:collection).tap { |c| c.set_viewables({ projects: [project.id] }) } }
      let(:other_collection) { create(:collection).tap { |c| c.set_viewables({ projects: [other_project.id] }) } }

      it 'is true with the permission on a collection holding the client project' do
        create(:access_control, role: marking_role, collection: client_collection, user_group: user_group)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be true
      end

      it 'is still true when the client is restricted' do
        create(:access_control, role: marking_role, collection: client_collection, user_group: user_group)
        restrict_destination
        expect(user.policy_for(destination_client).can_mark_restricted?).to be true
      end

      it 'is false when the role on the client project lacks the permission' do
        create(:access_control, role: viewing_role, collection: client_collection, user_group: user_group)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be false
      end

      it 'is false with the permission only on a collection for another project' do
        create(:access_control, role: viewing_role, collection: client_collection, user_group: user_group)
        create(:access_control, role: marking_role, collection: other_collection, user_group: user_group)
        expect(user.policy_for(destination_client).can_mark_restricted?).to be false
      end
    end
  end
end
