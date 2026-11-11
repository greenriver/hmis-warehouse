###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'shared_contexts/hidden_project_enrollment_context'

RSpec.describe Clients::CoordinatedEntryHudAssessmentsController, type: :request do
  include_context 'visibility test context'

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let!(:full_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: true, can_view_limited_client_dashboard: false }
  let!(:limited_dashboard_role) { create :role, can_view_clients: true, can_view_client_name: true, can_search_own_clients: true, can_view_full_client_dashboard: false, can_view_limited_client_dashboard: true }

  before { Collection.maintain_system_groups }

  include NamedHudAssessmentHelpers

  let(:window_assessment_attributes) do
    { data_source_id: window_visible_data_source.id, PersonalID: window_source_client.PersonalID, EnrollmentID: window_enrollment.EnrollmentID }
  end
  let!(:pathways_assessment) { create_named_hud_assessment('Pathways 2024', **window_assessment_attributes) }
  let!(:non_qualifying_assessment) { create_named_hud_assessment('Some Other Assessment', **window_assessment_attributes) }

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
      other_clients_pathways_assessment = create_named_hud_assessment(
        'Pathways 2024',
        data_source_id: non_window_visible_data_source.id,
        PersonalID: non_window_source_client.PersonalID,
        EnrollmentID: non_window_enrollment.EnrollmentID,
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

  describe 'enrollment scoping' do
    include_context 'hidden project enrollment context'

    let!(:visible_pathways) do
      create_named_hud_assessment('Pathways 2024', data_source_id: ds.id, PersonalID: hmis_client.PersonalID, EnrollmentID: visible_enrollment.EnrollmentID, AssessmentDate: Date.new(2024, 3, 3))
    end
    let!(:hidden_pathways) do
      create_named_hud_assessment('Pathways 2024', data_source_id: ds.id, PersonalID: hmis_client.PersonalID, EnrollmentID: hidden_enrollment.EnrollmentID, AssessmentDate: Date.new(2023, 4, 4))
    end

    before do
      config.update(client_dashboard: :boston)
      sign_in_with(viewer_role)
    end

    it 'shows the Pathways assessment recorded at the visible project' do
      get client_coordinated_entry_hud_assessment_path(destination, visible_pathways)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_pathways.AssessmentDate.to_s)
    end

    it 'does not show the Pathways assessment recorded at a project outside the collection' do
      # Pathways and on a visible client, so only the enrollment check can refuse.
      expect(hidden_pathways.pathways_or_transfer?).to be(true)
      expect(destination.show_demographics_to?(user)).to be(true)

      get client_coordinated_entry_hud_assessment_path(destination, hidden_pathways)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(hidden_pathways.AssessmentDate.to_s)
    end
  end
end
