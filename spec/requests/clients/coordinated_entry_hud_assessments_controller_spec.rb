###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe Clients::CoordinatedEntryHudAssessmentsController, type: :request do
  include_context 'visibility test context'

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let!(:full_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: true, can_view_limited_client_dashboard: false }
  let!(:limited_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: false, can_view_limited_client_dashboard: true }

  before { Collection.maintain_system_groups }

  def build_assessment(response_text:, data_source_id: window_visible_data_source.id, personal_id: window_source_client.PersonalID, enrollment_id: window_enrollment.EnrollmentID)
    assessment = create(:hud_assessment, data_source_id: data_source_id, PersonalID: personal_id, EnrollmentID: enrollment_id)
    GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: assessment.AssessmentID.to_s, response_text: response_text)
    create(
      :hud_assessment_question,
      data_source_id: data_source_id,
      AssessmentID: assessment.AssessmentID,
      AssessmentQuestion: 'c_housing_assessment_name',
      AssessmentAnswer: assessment.AssessmentID.to_s,
    )
    assessment
  end

  let!(:pathways_assessment) { build_assessment(response_text: 'Pathways 2024') }
  let!(:non_qualifying_assessment) { build_assessment(response_text: 'Some Other Assessment') }

  def sign_in_with(role)
    setup_access_control(user, role, Collection.system_collection(:window_data_sources))
    sign_in user
  end

  context 'when client_dashboard config is boston and the user has limited dashboard permission' do
    before do
      config.update(client_dashboard: :boston)
      sign_in_with(limited_dashboard_role)
    end

    it 'allows access to a pathways assessment' do
      get client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment)
      expect(response).to render_template(:show)
    end

    it 'logs the client access' do
      # ActivityLogger#compose_activity sets item_id from params[:id] (the assessment) before the action
      # runs; #log_item's `||=` guard means it only fills in item_model, not item_id, once that's already set.
      expect { get client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment) }.
        to change {
          ActivityLog.where(user_id: user.id, item_model: 'GrdaWarehouse::Hud::Client', item_id: pathways_assessment.id).count
        }.by(1)
    end

    it 'blocks access to a non-qualifying assessment' do
      get client_coordinated_entry_hud_assessment_path(window_destination_client, non_qualifying_assessment)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'blocks access to a qualifying assessment that belongs to a different client' do
      other_clients_pathways_assessment = build_assessment(
        response_text: 'Pathways 2024',
        data_source_id: non_window_visible_data_source.id,
        personal_id: non_window_source_client.PersonalID,
        enrollment_id: non_window_enrollment.EnrollmentID,
      )

      get client_coordinated_entry_hud_assessment_path(window_destination_client, other_clients_pathways_assessment)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when client_dashboard config is boston but the user has full (not limited) dashboard permission' do
    before do
      config.update(client_dashboard: :boston)
      sign_in_with(full_dashboard_role)
    end

    it 'blocks access to a pathways assessment' do
      get client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment)
      expect(response).to redirect_to(user.my_root_path)
    end
  end

  context 'when client_dashboard config is default and the user has limited dashboard permission' do
    before do
      config.update(client_dashboard: :default)
      sign_in_with(limited_dashboard_role)
    end

    it 'blocks access to a pathways assessment' do
      get client_coordinated_entry_hud_assessment_path(window_destination_client, pathways_assessment)
      expect(response).to redirect_to(user.my_root_path)
    end
  end
end
