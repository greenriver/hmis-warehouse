# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

# Tests Assessment.access schema fields are wired up correctly.
# See hmis_custom_assessment_policy_spec.rb for full policy coverage.
RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  before(:each) { hmis_login(user) }

  describe 'assessment access' do
    let(:access_query) do
      <<~GRAPHQL
        query AssessmentAccess($id: ID!) {
          assessment(id: $id) {
            id
            access {
              id
              canDeleteAssessment
            }
          }
        }
      GRAPHQL
    end

    def expect_assessment_access!(assessment:, can_delete_assessment:)
      response, result = post_graphql(id: assessment.id.to_s) { access_query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'assessment', 'access')).to include(
        'id' => assessment.id.to_s,
        'canDeleteAssessment' => can_delete_assessment,
      )
    end

    let(:view_permissions) { [:can_view_enrollment_details, :can_view_project] }

    it 'resolves canDeleteAssessment from the assessment policy (WIP + can_edit_enrollments)' do
      create_access_control(hmis_user, p1, with_permission: [:can_edit_enrollments, *view_permissions])
      assessment = create(:hmis_wip_custom_assessment, data_source: ds1, enrollment: e1, client: c1)

      expect_assessment_access!(assessment: assessment, can_delete_assessment: true)
    end

    it 'returns false when the policy denies delete' do
      create_access_control(hmis_user, p1, with_permission: [*view_permissions])
      assessment = create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, client: c1)

      expect_assessment_access!(assessment: assessment, can_delete_assessment: false)
    end
  end
end
