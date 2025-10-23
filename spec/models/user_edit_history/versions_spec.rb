###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserEditHistory::Versions do
  let(:user) { create(:user) }
  let(:versions) { described_class.new(user) }

  describe '#version_scope' do
    before do
      # Create login-related version
      create(:gr_paper_trail_version,
             item: user,
             object_changes: {
               'sign_in_count' => [1, 2],
               'current_sign_in_at' => [1.day.ago, Time.current],
               'updated_at' => [1.day.ago, Time.current],
             }.to_yaml)

      # Create non-login version
      create(:gr_paper_trail_version,
             item: user,
             object_changes: {
               'email' => ['old@example.com', 'new@example.com'],
               'updated_at' => [1.day.ago, Time.current],
             }.to_yaml)
    end

    it 'excludes login-related versions' do
      expect(versions.version_scope.count).to eq(1)
      expect(versions.version_scope.first.changeset.keys).to include('email')
    end
  end

  describe '#wrap_display_versions' do
    let!(:editor) { create(:user) }
    let!(:version) do
      create(:gr_paper_trail_version, item: user, whodunnit: editor.id.to_s)
    end

    it 'loads users' do
      display_items = versions.wrap_display_versions([version])
      expect(display_items.first.username).to eq(editor.name)
    end
  end

  describe '#version_scope cross-database merging' do
    let(:alert_definition) { create(:alert_definition, code: 'new_account', name: 'New Account') }
    let(:contact) { create(:grda_warehouse_contact_user, entity: user, user: user) }

    before do
      # Create a user version (primary database)
      create(
        :gr_paper_trail_version,
        item: user,
        object_changes: {
          'first_name' => ['Old', 'New'],
          'updated_at' => [2.days.ago, 1.day.ago],
        }.to_yaml,
        created_at: 1.day.ago,
      )

      # Create an alert subscription and its version (warehouse database)
      subscription = create(
        :contact_alert_subscription,
        contact: contact,
        alert_definition: alert_definition,
      )

      # Create a version for the subscription with recent timestamp
      create(
        :grda_warehouse_version,
        item_type: 'GrdaWarehouse::ContactAlertSubscription',
        item_id: subscription.id,
        event: 'create',
        referenced_user_id: user.id,
        object_changes: {
          'alert_definition_id' => [nil, alert_definition.id],
          'contact_id' => [nil, contact.id],
          'active' => [nil, true],
        }.to_yaml,
        created_at: Time.current,
      )
    end

    it 'returns an array, not a scope' do
      result = versions.version_scope
      expect(result).to be_a(Array)
    end

    it 'includes versions from both databases' do
      result = versions.version_scope

      expect(result.length).to eq(2)
      expect(result.map(&:class).uniq).to contain_exactly(
        GrPaperTrail::Version,
        GrdaWarehouse::Version,
      )
    end

    it 'sorts by created_at descending' do
      result = versions.version_scope

      expect(result.first).to be_a(GrdaWarehouse::Version) # More recent
      expect(result.second).to be_a(GrPaperTrail::Version) # Older
      expect(result.first.created_at).to be > result.second.created_at
    end

    it 'respects MAX_VERSIONS_PER_DATABASE limit' do
      stub_const('UserEditHistory::Versions::MAX_VERSIONS_PER_DATABASE', 1)

      # Create multiple versions in primary database
      3.times do
        create(
          :gr_paper_trail_version,
          item: user,
          object_changes: { 'email' => ['a@b.com', 'c@d.com'] }.to_yaml,
        )
      end

      # Create multiple subscriptions in warehouse database
      3.times do
        definition = create(:alert_definition)
        create(
          :contact_alert_subscription,
          contact: contact,
          alert_definition: definition,
        )
      end

      result = versions.version_scope

      # Should get 1 from primary + 1 from warehouse = 2 total (limited)
      # Without the limit, we'd have 4 user versions + 4 subscription versions = 8 total
      expect(result.length).to eq(2)
    end
  end
end
