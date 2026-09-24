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
end
