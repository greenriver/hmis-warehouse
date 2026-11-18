###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisAdmin::RolesController, type: :request do
  let!(:data_source) { create(:hmis_data_source) }
  let!(:admin_user) { create(:acl_user) }
  let!(:changed_role) { create(:hmis_role_with_no_permissions, name: 'Changed', can_view_project: true) }
  let!(:untouched_role) { create(:hmis_role_with_no_permissions, name: 'Untouched', can_view_project: true) }

  before do
    create_access_control(Hmis::User.find(admin_user.id), [])
    sign_in admin_user
  end

  describe 'PATCH /hmis_admin/roles/batch_update' do
    it 'updates the posted roles and leaves roles missing from the post unchanged' do
      patch batch_update_hmis_admin_roles_path, params: {
        role: { changed_role.id => { can_view_clients: '1', can_view_project: '0' } },
      }

      expect(response).to redirect_to(hmis_admin_roles_path)
      expect(flash[:notice]).to eq('All permissions saved')
      expect(changed_role.reload.slice(:can_view_clients, :can_view_project)).to eq('can_view_clients' => true, 'can_view_project' => false)
      expect(untouched_role.reload.slice(:can_view_clients, :can_view_project)).to eq('can_view_clients' => false, 'can_view_project' => true)
    end

    it 'rolls back every role and reports an error when a posted role no longer exists' do
      missing_id = Hmis::Role.maximum(:id) + 1

      patch batch_update_hmis_admin_roles_path, params: {
        role: {
          changed_role.id => { can_view_clients: '1' },
          missing_id => { can_view_clients: '1' },
        },
      }

      expect(response).to redirect_to(hmis_admin_roles_path)
      expect(flash[:error]).to eq('Error saving permissions')
      expect(changed_role.reload.can_view_clients).to be(false)
    end
  end
end
