###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hidden_project_enrollment_context'

RSpec.describe Clients::HudAssessmentsController, type: :request do
  let!(:user) { create :acl_user }
  let!(:can_view_enrollment_details) { create :role, can_view_enrollment_details: true, can_view_client_name: true, can_search_own_clients: true, can_view_clients: true }
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

    it 'renders the specifically requested assessment when the client has more than one' do
      assessment.update!(AssessmentDate: Date.new(2024, 6, 15))
      other_assessment = create(:hud_assessment, data_source_id: source_client.data_source_id, PersonalID: source_client.PersonalID, EnrollmentID: enrollment.EnrollmentID, AssessmentDate: Date.new(2020, 1, 1))

      get client_hud_assessment_path(client, other_assessment)
      expect(response.body).to include(other_assessment.AssessmentDate.to_s)
      expect(response.body).not_to include(assessment.AssessmentDate.to_s)

      get client_hud_assessment_path(client, assessment)
      expect(response.body).to include(assessment.AssessmentDate.to_s)
      expect(response.body).not_to include(other_assessment.AssessmentDate.to_s)
    end
  end

  context 'when the user lacks can_view_enrollment_details' do
    before { sign_in user }

    it 'blocks access' do
      get client_hud_assessment_path(client, assessment)
      expect(response).to redirect_to(user.my_root_path)
    end
  end

  describe 'enrollment and client scoping' do
    include_context 'hidden project enrollment context'

    let!(:visible_hud_assessment) { create(:hud_assessment, data_source_id: ds.id, PersonalID: hmis_client.PersonalID, EnrollmentID: visible_enrollment.EnrollmentID, AssessmentDate: Date.new(2024, 3, 3)) }
    let!(:hidden_hud_assessment) { create(:hud_assessment, data_source_id: ds.id, PersonalID: hmis_client.PersonalID, EnrollmentID: hidden_enrollment.EnrollmentID, AssessmentDate: Date.new(2023, 4, 4)) }

    context 'when the user can view the client through the visible project' do
      before { sign_in_with(viewer_role) }

      it 'shows the assessment recorded at the visible project' do
        get client_hud_assessment_path(destination, visible_hud_assessment)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(visible_hud_assessment.AssessmentDate.to_s)
      end

      it 'does not show the assessment recorded at a project outside the collection' do
        # The client is visible, the assessment is the client's, and only its enrollment is excluded, so only the enrollment check can refuse.
        expect(destination.show_demographics_to?(user)).to be(true)
        expect(destination.source_assessments.pluck(:id)).to include(hidden_hud_assessment.id)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: [visible_enrollment.id, hidden_enrollment.id]).pluck(:id)).to contain_exactly(visible_enrollment.id)

        get client_hud_assessment_path(destination, hidden_hud_assessment)

        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include(hidden_hud_assessment.AssessmentDate.to_s)
      end
    end

    context 'when the user can search the client but not view it' do
      before { sign_in_with(search_only_role) }

      it 'refuses the assessment because neither the client nor its enrollment is visible' do
        # Any grant that makes an enrollment visible also makes its client visible, so the client
        # scope and the enrollment condition can't be tested one at a time.
        expect(GrdaWarehouse::Hud::Client.destination_from_searchable_to(user).pluck(:id)).to include(destination.id)
        expect(destination.show_demographics_to?(user)).to be(false)
        expect(GrdaWarehouse::Hud::Enrollment.visible_to(user).where(id: visible_enrollment.id)).to be_empty

        get client_hud_assessment_path(destination, visible_hud_assessment)

        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include(visible_hud_assessment.AssessmentDate.to_s)
      end
    end
  end
end
