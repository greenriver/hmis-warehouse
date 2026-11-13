###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The Outcomes pages drop selected projects the user can't report on. A selection
# that resolves to nothing must report no projects, not every reportable one.
RSpec.describe WarehouseReport::Outcomes::RrhReport, type: :model do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:data_source) { create(:source_data_source) }
  # Non-confidential scoping joins the organization, so the projects need one
  let(:organization) { create(:hud_organization, data_source: data_source) }
  let(:rrh_type) { HudHelper.util.project_type_number_from_code(:rrh).first }
  let!(:reportable_project) do
    create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: rrh_type)
  end
  let!(:hidden_project) do
    create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: rrh_type)
  end

  before do
    collection = create(:collection)
    collection.set_viewables(projects: [reportable_project.id])
    setup_access_control(user, create(:role, can_view_assigned_reports: true), collection)
  end

  def report_for(project_ids)
    filter = WarehouseReport::Outcomes::OutcomesFilter.new(user_id: user.id, project_ids: project_ids)
    filter.project_type_numbers = [rrh_type]
    described_class.new(filter)
  end

  it 'reports no projects when every selected project is hidden' do
    report = report_for([hidden_project.id])

    expect(report.all_projects).to be false
    expect(report.projects).to be_empty
  end

  it 'reports the selected project when it is reportable' do
    report = report_for([reportable_project.id])

    expect(report.all_projects).to be false
    expect(report.projects.pluck(:id)).to eq([reportable_project.id])
  end

  it 'reports all reportable projects when nothing is selected' do
    expect(report_for([]).all_projects).to be true
  end
end
