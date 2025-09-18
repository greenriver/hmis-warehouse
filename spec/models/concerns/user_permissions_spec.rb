# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }
  let(:role) { create :role }

  describe '#can_view_some_client_dashboard' do
    context 'when user has no dashboard permissions' do
      it 'returns false' do
        expect(user.can_view_some_client_dashboard?).to be false
      end
    end

    context 'when user has can_view_full_client_dashboard permission' do
      before do
        role.update(can_view_full_client_dashboard: true)
        user.legacy_roles << role
        user.instance_variable_set(:@permissions, nil)
      end

      it 'returns true' do
        expect(user.can_view_some_client_dashboard?).to be true
      end
    end

    context 'when user has can_view_limited_client_dashboard permission' do
      before do
        role.update(can_view_limited_client_dashboard: true)
        user.legacy_roles << role
        user.instance_variable_set(:@permissions, nil)
      end

      it 'returns true' do
        expect(user.can_view_some_client_dashboard?).to be true
      end
    end

    context 'when user has both dashboard permissions' do
      before do
        role.update(
          can_view_full_client_dashboard: true,
          can_view_limited_client_dashboard: true,
        )
        user.legacy_roles << role
        user.instance_variable_set(:@permissions, nil)
      end

      it 'returns true' do
        expect(user.can_view_some_client_dashboard?).to be true
      end
    end

    context 'when user has other client permissions but no dashboard permissions' do
      before do
        role.update(can_view_clients: true, can_edit_clients: true)
        user.legacy_roles << role
        user.instance_variable_set(:@permissions, nil)
      end

      it 'returns false' do
        expect(user.can_view_some_client_dashboard?).to be false
      end
    end
  end
end
