###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::RolesController, type: :request do
  let(:admin) { create(:user) }
  let(:admin_role) { create(:admin_role) }
  let!(:changed_role) { create(:role, name: 'Changed', can_view_clients: false, can_view_projects: true) }
  let!(:untouched_role) { create(:role, name: 'Untouched', can_view_clients: false, can_view_projects: true) }

  before do
    admin.legacy_roles << admin_role
    sign_in admin
  end

  describe 'PATCH /admin/roles/batch_update' do
    it 'updates the posted roles and leaves roles missing from the post unchanged' do
      patch batch_update_admin_roles_path, params: {
        role: { changed_role.id => { can_view_clients: '1', can_view_projects: '0' } },
      }

      expect(response).to redirect_to(admin_roles_path)
      expect(flash[:notice]).to eq('All permissions saved')
      expect(changed_role.reload.slice(:can_view_clients, :can_view_projects)).to eq('can_view_clients' => true, 'can_view_projects' => false)
      expect(untouched_role.reload.slice(:can_view_clients, :can_view_projects)).to eq('can_view_clients' => false, 'can_view_projects' => true)
    end

    it 'rolls back every role and reports an error when a posted role no longer exists' do
      missing_id = Role.maximum(:id) + 1

      patch batch_update_admin_roles_path, params: {
        role: {
          changed_role.id => { can_view_clients: '1' },
          missing_id => { can_view_clients: '1' },
        },
      }

      expect(response).to redirect_to(admin_roles_path)
      expect(flash[:error]).to eq('Error saving permissions')
      expect(changed_role.reload.can_view_clients).to be(false)
    end
  end
end
