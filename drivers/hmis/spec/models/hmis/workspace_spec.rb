###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Workspace, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }
  let(:project_group) { create(:hmis_project_group, data_source: data_source) }

  describe 'validations' do
    subject(:workspace) { build(:hmis_workspace, data_source: data_source, project_group: project_group) }

    it { is_expected.to validate_inclusion_of(:applies_to).in_array(Hmis::Workspace::APPLIES_TO) }

    it 'requires an HMIS data source' do
      workspace.data_source = create(:source_data_source)
      expect(workspace).not_to be_valid
      expect(workspace.errors[:data_source]).to include('must be an HMIS data source')
    end

    it 'requires the project group to belong to the same data source' do
      workspace.project_group = create(:hmis_project_group, data_source: create(:hmis_data_source))
      expect(workspace).not_to be_valid
      expect(workspace.errors[:project_group]).to include('must belong to the same data source')
    end

    it 'requires slug to be unique by usage and data source' do
      create(:hmis_workspace, data_source: data_source, project_group: project_group, slug: 'housing')
      duplicate = build(:hmis_workspace, data_source: data_source, project_group: project_group, slug: 'housing')
      expect(duplicate).not_to be_valid
    end

    it 'allows the same slug for another data source' do
      create(:hmis_workspace, data_source: data_source, project_group: project_group, slug: 'housing')
      other_data_source = create(:hmis_data_source)
      other_group = create(:hmis_project_group, data_source: other_data_source)
      duplicate = build(:hmis_workspace, data_source: other_data_source, project_group: other_group, slug: 'housing')
      expect(duplicate).to be_valid
    end
  end

  describe '.viewable_by' do
    let!(:other_data_source) { create(:hmis_data_source) }
    let!(:other_project_group) { create(:hmis_project_group, data_source: other_data_source) }
    let!(:workspace) { create(:hmis_workspace, data_source: data_source, project_group: project_group) }
    let!(:workspace_other_data_source) do
      create(:hmis_workspace, data_source: other_data_source, project_group: other_project_group)
    end

    let!(:user_with_access) do
      user = create(:hmis_user, data_source: data_source)
      create_access_control(user, data_source, with_permission: [:can_view_referrals])
      user
    end

    let!(:user_without_access) do
      user = create(:hmis_user, data_source: data_source)
      create_access_control(user, data_source, with_permission: [:can_view_project])
      user
    end

    before do
      allow(Hmis::Ce.configuration).to receive(:enabled?).and_return(true)
    end

    it 'returns ce_referrals workspaces in the user data source when they can index referrals' do
      result = described_class.viewable_by(user_with_access, for_usage: Hmis::Workspace::CE_REFERRALS)
      expect(result).to contain_exactly(workspace)
    end

    it 'returns none when the user cannot index ce referrals' do
      result = described_class.viewable_by(user_without_access, for_usage: Hmis::Workspace::CE_REFERRALS)
      expect(result).to be_empty
    end

    it 'includes workspaces when the user has can_view_own_referrals' do
      user = create(:hmis_user, data_source: data_source)
      create_access_control(user, data_source, with_permission: [:can_view_own_referrals])

      result = described_class.viewable_by(user, for_usage: Hmis::Workspace::CE_REFERRALS)
      expect(result).to contain_exactly(workspace)
    end

    it 'raises for an unimplemented usage' do
      expect do
        described_class.viewable_by(user_with_access, for_usage: 'dashboard')
      end.to raise_error(NotImplementedError, /not implemented for applies_to: dashboard/)
    end
  end
end
