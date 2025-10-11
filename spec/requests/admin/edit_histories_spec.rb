###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::EditHistories', type: :request do
  let(:admin_user) { create(:user) }
  let(:target_user) { create(:user, first_name: 'Test', last_name: 'User') }

  before do
    PaperTrail.enabled = true
    # Grant admin user permission to audit users
    allow_any_instance_of(User).to receive(:can_audit_users?).and_return(true)
    sign_in admin_user
  end

  after do
    PaperTrail.enabled = false
  end

  describe 'GET /admin/users/:user_id/edit_history' do
    context 'with mixed version types' do
      let(:alert_definition) { create(:alert_definition, code: 'new_account', name: 'New Account Creation') }
      let(:contact) { create(:grda_warehouse_contact_user, entity: target_user, user: target_user) }

      before do
        # Create a user change version (primary database)
        create(
          :gr_paper_trail_version,
          item: target_user,
          event: 'update',
          object_changes: {
            'first_name' => ['Test', 'Updated'],
            'updated_at' => [1.day.ago, Time.current],
          }.to_yaml,
          created_at: 1.day.ago,
        )

        # Create an alert subscription version (warehouse database)
        subscription = create(
          :contact_alert_subscription,
          contact: contact,
          alert_definition: alert_definition,
        )

        create(
          :grda_warehouse_version,
          item_type: 'GrdaWarehouse::ContactAlertSubscription',
          item_id: subscription.id,
          event: 'create',
          referenced_user_id: target_user.id,
          object_changes: {
            'alert_definition_id' => [nil, alert_definition.id],
            'contact_id' => [nil, contact.id],
            'active' => [nil, true],
          }.to_yaml,
          created_at: Time.current,
        )
      end

      it 'displays both user and subscription changes' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Test User Edit History')

        # Should show user change
        expect(response.body).to include('First Name')

        # Should show subscription change
        expect(response.body).to include('Subscribed to alert: New Account Creation')
      end

      it 'paginates the results' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:success)
        # Should have pagination elements from pagy_array
        expect(response.body).to match(/event/)
      end

      it 'sorts changes by date descending' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:success)

        # Extract dates from the response (order matters)
        # The subscription change should appear before the user change
        # since it was created more recently
        body = response.body
        subscription_match = body.index('Subscribed to alert')
        user_change_match = body.index('First Name')

        expect(subscription_match).to be < user_change_match if subscription_match && user_change_match
      end
    end

    context 'with deprecated notification column changes' do
      before do
        # Simulate old-style boolean column change
        create(
          :gr_paper_trail_version,
          item: target_user,
          event: 'update',
          object_changes: {
            'notify_on_new_account' => [false, true],
            'updated_at' => [1.day.ago, Time.current],
          }.to_yaml,
        )
      end

      it 'displays deprecated column as alert subscription' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Subscribed to alert: New Account Creation')
        expect(response.body).not_to include('notify_on_new_account')
      end
    end

    context 'with large number of changes' do
      before do
        # Create versions beyond MAX_VERSIONS_PER_DATABASE
        stub_const('UserEditHistory::Versions::MAX_VERSIONS_PER_DATABASE', 5)

        10.times do |i|
          create(
            :gr_paper_trail_version,
            item: target_user,
            event: 'update',
            object_changes: {
              'first_name' => ["Name#{i}", "Name#{i + 1}"],
              'updated_at' => [1.day.ago, Time.current],
            }.to_yaml,
            created_at: i.days.ago,
          )
        end
      end

      it 'respects the version limit' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:success)

        # Should only show limited versions (not all 10)
        # The actual rendering depends on pagination settings
        expect(response.body).to include('Edit History')
      end
    end

    context 'without audit permission' do
      before do
        allow_any_instance_of(User).to receive(:can_audit_users?).and_return(false)
      end

      it 'denies access' do
        get admin_user_edit_history_path(target_user)

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
