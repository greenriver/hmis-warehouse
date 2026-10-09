###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProjectScorecard::WarehouseReports::ScorecardsController contact links', type: :request do
  include_context 'report visibility users'

  let(:report_class) { ProjectScorecard::Report }
  let(:report_definition_url) { 'project_scorecard/warehouse_reports/scorecards' }
  let(:organization) { create(:hud_organization) }
  let(:project) { create(:hud_project, data_source: organization.data_source, OrganizationID: organization.OrganizationID) }
  let(:report) { report_class.create!(user_id: user.id, project_id: project.id, status: 'pre-filled') }

  before { sign_in(user) }

  context 'when the user can manage contacts' do
    let(:user) { user_with_role(can_view_assigned_reports: true, can_view_imports: true) }

    it 'links the no-contacts warning to the project and organization contacts pages' do
      get edit_project_scorecard_warehouse_reports_scorecard_path(report)

      expect(response.body).to include(project_contacts_path(project), organization_contacts_path(organization))
    end
  end

  context 'when the user cannot manage contacts' do
    let(:user) { own_reports_user }

    it 'shows the no-contacts warning without links' do
      get edit_project_scorecard_warehouse_reports_scorecard_path(report)

      expect(response.body).to include('There are no contacts specified')
      expect(response.body).not_to include(project_contacts_path(project))
      expect(response.body).not_to include(organization_contacts_path(organization))
    end
  end
end
