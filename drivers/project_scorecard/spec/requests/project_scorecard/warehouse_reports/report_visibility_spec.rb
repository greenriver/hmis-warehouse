###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProjectScorecard::WarehouseReports::ScorecardsController visibility', type: :request do
  let(:report_class) { ProjectScorecard::Report }
  let(:report_definition_url) { 'project_scorecard/warehouse_reports/scorecards' }
  let(:report_path) { ->(report) { project_scorecard_warehouse_reports_scorecard_path(report) } }

  it_behaves_like 'report member actions limited to visible reports', destroy: false

  describe 'history' do
    include_context 'report visibility users'

    let(:contact_project) { create(:hud_project) }
    let(:other_project) { create(:hud_project) }
    let!(:contact_report) { report_class.create!(user_id: all_reports_user.id, project_id: contact_project.id, started_at: Time.current) }
    let!(:other_report) { report_class.create!(user_id: all_reports_user.id, project_id: other_project.id, started_at: Time.current) }

    before do
      create(:grda_warehouse_contact_project, user: own_reports_user, entity: contact_project)
      sign_in(own_reports_user)
    end

    it 'lists scorecards for projects the user is a contact on, without access to the project' do
      get history_project_scorecard_warehouse_reports_scorecards_path

      expect(response.body).to include(edit_project_scorecard_warehouse_reports_scorecard_path(contact_report))
      expect(response.body).not_to include(edit_project_scorecard_warehouse_reports_scorecard_path(other_report))
    end

    it 'omits scorecards whose project or project group was deleted' do
      group = create(:project_group)
      group_report = report_class.create!(user_id: own_reports_user.id, project_group_id: group.id, started_at: Time.current)
      group.destroy
      contact_project.destroy

      get history_project_scorecard_warehouse_reports_scorecards_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(edit_project_scorecard_warehouse_reports_scorecard_path(contact_report))
      expect(response.body).not_to include(edit_project_scorecard_warehouse_reports_scorecard_path(group_report))
    end
  end
end
