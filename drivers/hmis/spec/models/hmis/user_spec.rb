###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::User, type: :model do
  include_context 'hmis base setup'

  let(:hmis_user) { create(:hmis_user) }

  describe '#full_name' do
    it 'joins first and last name' do
      user = build(:hmis_user, first_name: 'Jane', last_name: 'Doe')
      expect(user.full_name).to eq('Jane Doe')
    end

    it 'returns nil when both names are blank' do
      user = build(:hmis_user, first_name: '', last_name: '')
      expect(user.full_name).to be_nil
    end
  end

  describe '#update_unique_session_id!' do
    it 'writes to hmis_unique_session_id' do
      hmis_user.update_unique_session_id!('hmis-session-abc')
      hmis_user.reload

      expect(hmis_user.hmis_unique_session_id).to eq('hmis-session-abc')
    end

    it 'leaves the warehouse unique_session_id column untouched' do
      # alias_attribute aliases unique_session_id -> hmis_unique_session_id on the model,
      # so we query the raw column directly to verify isolation.
      uid = hmis_user.id.to_i
      raw_before = ApplicationRecord.connection.select_value(
        ApplicationRecord.sanitize_sql_array(['SELECT unique_session_id FROM users WHERE id = ?', uid]),
      )

      hmis_user.update_unique_session_id!('hmis-session-abc')

      raw_after = ApplicationRecord.connection.select_value(
        ApplicationRecord.sanitize_sql_array(['SELECT unique_session_id FROM users WHERE id = ?', uid]),
      )

      expect(raw_after).to eq(raw_before)
    end

    it 'raises NotPersistedError when called on an unsaved record' do
      new_user = build(:hmis_user)
      expect { new_user.update_unique_session_id!('x') }.to raise_error(Devise::Models::Compatibility::NotPersistedError)
    end
  end

  describe '.with_hmis_access_in_data_source' do
    let!(:ds2) { create(:hmis_data_source) }

    let!(:this_ds_user) { create(:hmis_user, data_source: ds1) }
    let!(:other_ds_user) { create(:hmis_user, data_source: ds2) }
    let!(:warehouse_only_user) { create(:user, first_name: 'Warehouse Only') }

    before do
      create_access_control(this_ds_user, ds1)
      create_access_control(other_ds_user, ds2)
    end

    it 'includes only users with HMIS access in the requested data source' do
      users = Hmis::User.with_hmis_access_in_data_source(ds1.id)

      expect(users).to include(this_ds_user)
      expect(users).not_to include(other_ds_user)
      expect(users).not_to include(warehouse_only_user)
    end
  end

  describe '.with_hmis_historic_access' do
    let!(:ds2) { create(:hmis_data_source) }

    let!(:this_ds_user) { create(:hmis_user, data_source: ds1) }
    let!(:other_ds_user) { create(:hmis_user, data_source: ds2) }
    let!(:warehouse_only_user) { create(:user, first_name: 'Warehouse Only') }

    before do
      create_access_control(this_ds_user, ds1)
      create_access_control(other_ds_user, ds2)
    end

    # The letters in each test description correspond to lettered cases in the block-comment description on the with_hmis_historic_access scope.
    it 'includes current HMIS users for the data source and excludes unrelated users (A)' do
      users = Hmis::User.with_hmis_historic_access(ds1.id)

      expect(users).to include(this_ds_user)
      expect(users).not_to include(other_ds_user)
      expect(users).not_to include(warehouse_only_user)
    end

    it 'includes user who was removed from a user group (B)' do
      removed_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(removed_user, ds1)
      access_control.user_group.remove(removed_user)

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(removed_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(removed_user)
    end

    it 'includes user who had access through a user group that got deleted (C)' do
      former_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(former_user, ds1)
      access_control.user_group.destroy!

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user who had access through an access control that got deleted (D)' do
      former_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(former_user, ds1)
      access_control.destroy!

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user whose access control and user group were both deleted (C and D)' do
      former_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(former_user, ds1)
      access_control.user_group.destroy!
      access_control.destroy!

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user who previously had access but the data source was removed from the collection (E)' do
      former_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(former_user, ds1)
      gve = Hmis::GroupViewableEntity.find_by!(collection_id: access_control.access_group_id, entity: ds1)
      gve.destroy!

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user who was deleted (F)' do
      former_user = create(:hmis_user, data_source: ds1)
      create_access_control(former_user, ds1)
      former_user.destroy!

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user whose access control was updated and no longer points at this collection (G)' do
      former_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(former_user, ds1)
      other_collection = create(:hmis_access_group, with_entities: ds2)
      access_control.update!(access_group: other_collection)

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(former_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(former_user)
    end

    it 'includes user whose access control was updated and no longer points at this user group (H)' do
      ug1 = create(:hmis_user_group)
      ug2 = create(:hmis_user_group)
      reassigned_user = create(:hmis_user, data_source: ds1)
      access_control = create_access_control(reassigned_user, ds1, user_group: ug1)
      access_control.update!(user_group: ug2)

      expect(Hmis::User.with_hmis_access_in_data_source(ds1.id)).not_to include(reassigned_user)
      expect(Hmis::User.with_hmis_historic_access(ds1.id)).to include(reassigned_user)
    end

    it 'does not include users removed from a user group that was never tied to this data source' do
      user = create(:hmis_user, data_source: ds1)
      unrelated_group = create(:hmis_user_group)
      unrelated_group.add(user)
      unrelated_group.remove(user)

      expect(Hmis::User.with_hmis_historic_access(ds1.id)).not_to include(user)
    end

    it 'does not include users whose only historic access control was unrelated to this data source' do
      only_other_ds_user = create(:hmis_user, data_source: ds2)
      other_ac = create_access_control(only_other_ds_user, ds2)
      other_ac.destroy!

      expect(Hmis::User.with_hmis_historic_access(ds1.id)).not_to include(only_other_ds_user)
    end
  end

  describe 'permission methods' do
    let!(:user_with_role) { create(:hmis_user, data_source: ds1) }
    let!(:user_without_role) { create(:hmis_user, data_source: ds1) }

    before do
      create_access_control(user_with_role, ds1, with_permission: :can_view_project)
    end

    it 'returns true for a permission granted via a role' do
      expect(user_with_role.can_view_project?).to be true
    end

    it 'returns falsey when the user has no roles granting the permission' do
      expect(user_without_role.can_view_project?).to be_falsey
    end

    it 'supports multi-permission check with mode: :all' do
      expect(user_with_role.permissions?(:can_view_project, :can_edit_enrollments, mode: :all)).to be false
      expect(user_with_role.permissions?(:can_view_project, mode: :all)).to be true
    end
  end

  describe 'CVE-2026-32700 - confirmation token/unconfirmed_email sync' do
    it 'prevents desync when a concurrent request modifies unconfirmed_email mid-flight' do
      attacker_email = 'attacker@example.com'
      victim_email   = 'victim@example.com'

      user = create(:hmis_user)
      # HMIS skips confirmation routes, so stub the notification to avoid routing errors
      allow(user).to receive(:send_devise_notification)

      # First email change — clears dirty tracking; in-memory clean value is now attacker_email
      user.update!(email: attacker_email)

      # Simulate a concurrent request stomping unconfirmed_email in the DB
      # while the attacker's AR instance is still in memory
      Hmis::User.where(id: user.id).update_all(
        unconfirmed_email: victim_email,
        confirmation_token: 'injected_token',
      )

      # Second update with the same email — without the patch, AR considers
      # unconfirmed_email unchanged (still attacker_email in memory) and
      # omits it from the UPDATE, leaving victim_email in the DB
      user.update!(email: attacker_email)

      user.reload
      expect(user.unconfirmed_email).to eq(attacker_email)
      expect(user.confirmation_token).not_to eq('injected_token')
    end
  end
end
