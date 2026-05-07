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
end
