###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::HmisOrganizationPolicy, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let!(:other_organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  describe 'Instance' do
    let(:policy) { user.policy_for(organization, policy_type: :hmis_organization) }

    describe '#can_edit?' do
      it 'returns false without permissions' do
        expect(policy.can_edit?).to be false
      end

      context 'with can_edit_organization permission' do
        let!(:access_control) { create_access_control(user, organization, with_permission: :can_edit_organization) }

        it 'returns true' do
          expect(policy.can_edit?).to be true
        end
      end

      context 'when permissions are only granted on a different organization' do
        let!(:access_control) { create_access_control(user, other_organization) } # full perms at other org

        it 'returns false' do
          expect(policy.can_edit?).to be false
        end
      end
    end

    describe '#can_create_project?' do
      it 'returns false without permissions' do
        expect(policy.can_create_project?).to be false
      end

      context 'with can_view_project and can_edit_project_details' do
        let!(:access_control) { create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details]) }

        it 'returns true' do
          expect(policy.can_create_project?).to be true
        end
      end
    end

    describe '#can_delete?' do
      it 'returns false without permissions' do
        expect(policy.can_delete?).to be false
      end

      context 'with can_delete_organization permission' do
        let!(:access_control) { create_access_control(user, organization, with_permission: :can_delete_organization) }

        it 'returns true' do
          expect(policy.can_delete?).to be true
        end
      end
    end
  end

  describe 'Global' do
    let(:policy) { user.policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization) }

    describe '#can_create?' do
      it 'returns false without permissions' do
        expect(policy.can_create?).to be false
      end

      context 'with can_edit_organization at the data source' do
        before { create_access_control(user, data_source, with_permission: :can_edit_organization) }

        it 'returns true' do
          expect(policy.can_create?).to be true
        end
      end
    end
  end
end
