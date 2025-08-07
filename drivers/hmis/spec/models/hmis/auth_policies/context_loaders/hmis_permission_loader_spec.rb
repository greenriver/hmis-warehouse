# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::ContextLoaders::HmisPermissionLoader, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, hmis_data_source_id: data_source.id) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:loader) { described_class.new(user) }

  describe '#for_access_group_ids' do
    it 'returns empty set when no access groups provided' do
      expect(loader.for_access_group_ids([])).to eq(Set.new)
    end

    context 'with permission requirements' do
      it 'includes permissions when requirements are met' do
        access_control = create_access_control(user, project, with_permission: [:can_view_project, :can_view_referrals, :can_start_referrals])

        result = loader.for_access_group_ids([access_control.access_group.id])

        expect(result).to include(:can_view_project, :can_view_referrals, :can_start_referrals)
      end

      it 'excludes permissions when requirements are not met' do
        access_control = create_access_control(user, project, with_permission: [:can_view_project, :can_start_referrals])

        result = loader.for_access_group_ids([access_control.access_group.id])

        expect(result.to_a).to eq([:can_view_project]) # can_start_referrals filtered out due to unmet requirements
      end
    end
  end
end
