###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectScorecard::Report, type: :model do
  include_context 'report visibility users'

  let(:report_class) { described_class }
  let(:report_definition_url) { 'project_scorecard/warehouse_reports/scorecards' }
  let(:contact_user) { own_reports_user }

  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:organization) { create(:hud_organization, data_source: data_source, OrganizationID: 'ORG-1') }
  let(:project) { create(:hud_project, data_source: data_source, OrganizationID: 'ORG-2') }
  let(:organization_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  # Same OrganizationID as the contacted organization, but a different data source.
  let(:other_source_project) { create(:hud_project, OrganizationID: organization.OrganizationID) }

  def create_report(**attributes)
    described_class.create!(user_id: all_reports_user.id, **attributes)
  end

  def group_with(*projects)
    create(:project_group).tap { |group| group.projects = projects }
  end

  before do
    create(:grda_warehouse_contact_project, user: contact_user, entity: project)
    create(:grda_warehouse_contact_organization, user: contact_user, entity: organization)
    create(:grda_warehouse_contact_project, user: all_reports_user, entity: other_source_project)
  end

  let!(:project_contact_report) { create_report(project_id: project.id) }
  let!(:organization_contact_report) { create_report(project_id: organization_project.id) }
  let!(:group_project_contact_report) { create_report(project_group_id: group_with(project).id) }
  let!(:group_organization_contact_report) { create_report(project_group_id: group_with(organization_project).id) }
  let!(:unrelated_project_report) { create_report(project_id: other_source_project.id) }
  let!(:unrelated_group_report) { create_report(project_group_id: group_with(other_source_project).id) }

  it 'returns created and contact scorecards to a user who can view assigned reports' do
    expect(described_class.viewable_by(contact_user)).to contain_exactly(
      own_report,
      project_contact_report,
      organization_contact_report,
      group_project_contact_report,
      group_organization_contact_report,
    )
  end

  it 'returns every scorecard to a user who can view all reports' do
    expect(described_class.viewable_by(all_reports_user)).to contain_exactly(
      own_report,
      others_report,
      project_contact_report,
      organization_contact_report,
      group_project_contact_report,
      group_organization_contact_report,
      unrelated_project_report,
      unrelated_group_report,
    )
  end

  it 'returns nothing to a contact without a report permission' do
    user = user_with_role(can_view_clients: true)
    create(:grda_warehouse_contact_project, user: user, entity: project)
    create_report(project_id: project.id, user_id: user.id)

    expect(described_class.viewable_by(user)).to be_empty
  end

  it 'excludes a scorecard once the contact is removed' do
    GrdaWarehouse::Contact::Project.where(user_id: contact_user.id).destroy_all

    expect(described_class.viewable_by(contact_user)).not_to include(project_contact_report, group_project_contact_report)
  end
end
