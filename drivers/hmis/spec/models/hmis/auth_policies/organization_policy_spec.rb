###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  describe 'Instance policy' do
    let(:policy) { user.policy_for(organization, policy_type: :hmis_organization) }

    context 'with can_edit_organization permission' do
      let!(:access_control) { create_access_control(user, organization, with_permission: :can_edit_organization) }

      it 'grants can_edit?' do
        expect(policy.can_edit?).to be true
      end
    end

    context 'with can_edit_project_details permission' do
      let!(:access_control) { create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details]) }

      it 'grants can_create_project?' do
        expect(policy.can_create_project?).to be true
      end
    end

    context 'without permissions (even if permissions are granted at another organization)' do
      let!(:access_control) { create_access_control(user, other_organization, with_permission: [:can_edit_organization, :can_view_project, :can_edit_project_details]) }

      it 'denies can_edit?' do
        expect(policy.can_edit?).to be false
      end

      it 'denies can_create_project?' do
        expect(policy.can_create_project?).to be false
      end
    end
  end

  describe 'Global policy' do
    let(:policy) { user.policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization) }

    context 'with can_edit_organization permission' do
      before { create_access_control(user, data_source, with_permission: :can_edit_organization) }

      it 'grants can_create?' do
        expect(policy.can_create?).to be true
      end
    end

    context 'without can_edit_organization permission' do
      it 'denies can_create?' do
        expect(policy.can_create?).to be false
      end
    end
  end
end
