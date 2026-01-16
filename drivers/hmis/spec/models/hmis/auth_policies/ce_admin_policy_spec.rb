# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::CeAdminPolicy, type: :model do
  let!(:data_source) { create(:hmis_data_source) }
  # data source has to have at least one project, otherwise the logic "has permission for any entity in this data source" will not work
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }
  let!(:user) { create(:hmis_user, data_source: data_source) }
  let!(:user2) { create(:hmis_user, data_source: data_source) }
  let!(:policy) { user.policy_for(data_source, policy_type: :ce_admin) }
  let!(:access_control) { create_access_control(user, data_source, with_permission: [:can_administrate_coordinated_entry]) }

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  describe '#can_manage_ce_default_contacts?' do
    it 'returns true when user has can_administrate_coordinated_entry permission' do
      expect(policy.can_manage_ce_default_contacts?).to be true
    end

    it 'returns false when user lacks permission' do
      remove_permissions(access_control, :can_administrate_coordinated_entry)
      create_access_control(user2, data_source, with_permission: [:can_administrate_coordinated_entry])
      expect(policy.can_manage_ce_default_contacts?).to be false
    end

    context 'in multi-hmis installation' do
      let!(:ds2) { create(:hmis_data_source) }
      let!(:project2) { create(:hmis_hud_project, data_source: ds2) }
      let!(:access_control) { create_access_control(user, ds2, with_permission: [:can_administrate_coordinated_entry]) }

      it 'returns false when user only has permission in a different data source' do
        expect(policy.can_manage_ce_default_contacts?).to be false
      end
    end

    context 'when user has permission at project level only' do
      let!(:project) { create(:hmis_hud_project, data_source: data_source) }
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_administrate_coordinated_entry]) }

      it 'returns false' do
        expect(policy.can_manage_ce_default_contacts?).to be false
      end
    end

    context 'when there are many projects in the data source' do
      before do
        20.times do
          create(:hmis_hud_project, data_source: data_source)
        end
      end

      it 'makes a reasonable number of queries' do
        expect do
          expect(policy.can_manage_ce_default_contacts?).to be true
        end.to make_database_queries(count: 0..3)
      end
    end
  end
end
