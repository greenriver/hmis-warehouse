###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::Base, type: :model do
  describe '#title for a confidential project' do
    let!(:data_source) { create :source_data_source }
    let!(:organization) { create :hud_organization, data_source_id: data_source.id, OrganizationName: 'Zebra Org Secret' }
    let!(:project) { create :hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectName: 'Zebra Project Secret', confidential: true }
    let!(:other_project) { create :hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID }
    let!(:user) { create :acl_user }
    let!(:view_role) { create :role, can_view_projects: true }
    let!(:names_role) { create :can_view_confidential_projects }
    let!(:own_collection) { create :collection }
    let!(:elsewhere_collection) { create :collection }
    let(:report) { described_class.new(project: project) }

    before do
      own_collection.set_viewables({ projects: [project.id] })
      elsewhere_collection.set_viewables({ projects: [other_project.id] })
      setup_access_control(user, view_role, own_collection)
    end

    it 'excludes project and organization names when the name permission is held elsewhere' do
      setup_access_control(user, names_role, elsewhere_collection)

      expect(report.title(user)).to eq "#{GrdaWarehouse::Hud::Project.confidential_project_name} at #{GrdaWarehouse::Hud::Organization.confidential_organization_name}"
    end

    it 'includes project and organization names when the name permission covers the project' do
      setup_access_control(user, names_role, own_collection)

      expect(report.title(user)).to eq 'Zebra Project Secret at Zebra Org Secret'
    end
  end
end
