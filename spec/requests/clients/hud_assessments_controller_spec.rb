###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clients::HudAssessmentsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:can_view_enrollment_details) { create :role, can_view_enrollment_details: true, can_view_client_name: true, can_search_own_clients: true }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:client) { warehouse_client.destination }
  let!(:source_client) { warehouse_client.source }
  let!(:project) { create(:hud_project, data_source_id: source_client.data_source_id) }
  let!(:enrollment) { create(:hud_enrollment, data_source_id: source_client.data_source_id, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID) }
  let!(:assessment) { create(:hud_assessment, data_source_id: source_client.data_source_id, PersonalID: source_client.PersonalID, EnrollmentID: enrollment.EnrollmentID) }
  let!(:no_data_source_collection) { create :collection }

  before { no_data_source_collection.set_viewables({ data_sources: GrdaWarehouse::DataSource.authoritative.pluck(:id) }) }

  context 'when the user has can_view_enrollment_details' do
    before do
      setup_access_control(user, can_view_enrollment_details, no_data_source_collection)
      sign_in user
    end

    it 'renders the assessment details' do
      get client_hud_assessment_path(client, assessment)
      expect(response).to render_template(:show)
    end
  end

  context 'when the user lacks can_view_enrollment_details' do
    before { sign_in user }

    it 'blocks access' do
      get client_hud_assessment_path(client, assessment)
      expect(response).to redirect_to(user.my_root_path)
    end
  end
end
