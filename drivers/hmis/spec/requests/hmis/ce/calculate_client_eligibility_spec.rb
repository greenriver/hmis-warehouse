# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::CalculateClientEligibility, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:client) { create :hmis_hud_client_with_warehouse_client, data_source: ds1, dob: 30.years.ago }
  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: client }

  let!(:form_definition) do
    definition = {
      "item": [
        { "link_id": 'veteran_q', "mapping": { "custom_field_key": 'veteran_field' } },
        { "link_id": 'unmapped_q' },
      ],
    }
    create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, definition: definition, identifier: 'test_form', status: :published)
  end

  let!(:veteran_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: :veteran_field, data_source: ds1) }
  let!(:veteran_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: '`cde.custom_assessment.veteran_field` = 1' }
  let!(:general_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: 'current_age > 18' }

  let!(:veteran_project) { create :hmis_hud_project, data_source: ds1, project_type: 1 }
  let!(:veteran_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: veteran_project) }
  let!(:general_project) { create :hmis_hud_project, data_source: ds1, project_type: 2 }
  let!(:general_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: general_project) }

  let!(:veteran_unit_group) { create :hmis_unit_group, project: veteran_project, candidate_pool: veteran_pool }
  let!(:general_unit_group) { create :hmis_unit_group, project: general_project, candidate_pool: general_pool }

  let(:mutation) do
    <<~GRAPHQL
      mutation($enrollmentId: ID!, $formDefinitionIdentifier: String!, $valuesByLinkId: JsonObject!) {
        calculateClientEligibility(enrollmentId: $enrollmentId, formDefinitionIdentifier: $formDefinitionIdentifier, valuesByLinkId: $valuesByLinkId) {
          projectTypes
          errors { fullMessage }
        }
      }
    GRAPHQL
  end

  describe 'calculateClientEligibility' do
    it 'returns project types for eligible pools' do
      response, result = post_graphql(
        enrollmentId: enrollment.id,
        formDefinitionIdentifier: form_definition.identifier,
        valuesByLinkId: { 'veteran_q' => 1, 'unmapped_q' => 'ignored' },
      ) { mutation }

      expect(response.status).to eq(200), result.inspect
      project_types = result.dig('data', 'calculateClientEligibility', 'projectTypes')
      project_type_ids = project_types.map { |pt| Types::HmisSchema::Enums::Hud::ProjectTypeBrief.value_for(pt) }
      expect(project_type_ids).to contain_exactly(veteran_project.project_type, general_project.project_type) # Both pools match
    end

    it 'returns subset when fewer pools match' do
      response, result = post_graphql(
        enrollmentId: enrollment.id,
        formDefinitionIdentifier: form_definition.identifier,
        valuesByLinkId: { 'veteran_q' => 0 },
      ) { mutation }

      expect(response.status).to eq(200), result.inspect
      project_types = result.dig('data', 'calculateClientEligibility', 'projectTypes')
      project_type_ids = project_types.map { |pt| Types::HmisSchema::Enums::Hud::ProjectTypeBrief.value_for(pt) }
      expect(project_type_ids).to contain_exactly(2) # Only general pool
    end
  end
end
