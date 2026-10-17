###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Project, '.project_ids_in_collections', type: :model do
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:other_organization) { create :hud_organization, data_source: data_source }
  let!(:direct_project) { create :hud_project, data_source: data_source, OrganizationID: other_organization.OrganizationID }
  let!(:organization_project) { create :hud_project, data_source: data_source, OrganizationID: organization.OrganizationID }
  let!(:other_collection_project) { create :hud_project, data_source: data_source, OrganizationID: other_organization.OrganizationID }
  let(:collection) { create(:collection).tap { |c| c.set_viewables(projects: [direct_project.id], organizations: [organization.id]) } }

  before do
    create(:collection).set_viewables(projects: [other_collection_project.id])
  end

  it 'returns projects attached directly and through an organization in the given collection' do
    expect(described_class.project_ids_in_collections([collection.id])).to contain_exactly(direct_project.id, organization_project.id)
  end

  it 'returns an empty set for no collections' do
    expect(described_class.project_ids_in_collections([])).to eq(Set.new)
  end
end
