# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1) }
  let!(:other_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1) }

  let!(:newer_assessment) do
    create(
      :hmis_hud_assessment,
      data_source: ds1,
      client: c1,
      enrollment: enrollment,
      assessment_date: Date.new(2024, 2, 1),
      date_updated: 3.days.ago,
    )
  end

  let!(:recently_updated_assessment) do
    create(
      :hmis_hud_assessment,
      data_source: ds1,
      client: c1,
      enrollment: enrollment,
      assessment_date: Date.new(2024, 1, 1),
      date_updated: 1.day.ago,
    )
  end

  let!(:other_enrollment_assessment) do
    create(
      :hmis_hud_assessment,
      data_source: ds1,
      client: c1,
      enrollment: other_enrollment,
      assessment_date: Date.new(2024, 3, 1),
      date_updated: Time.current,
    )
  end

  let(:query) do
    <<~GRAPHQL
      query GetEnrollmentCeAssessments($id: ID!, $sortOrder: AssessmentSortOption = null) {
        enrollment(id: $id) {
          id
          ceAssessments(sortOrder: $sortOrder) {
            nodesCount
            nodes {
              id
              assessmentDate
            }
          }
        }
      }
    GRAPHQL
  end

  def perform_ce_assessments_query(sort_order: nil)
    variables = { id: enrollment.id.to_s }
    variables[:sort_order] = sort_order if sort_order.present?

    response, result = post_graphql(**variables) { query }
    expect(response.status).to eq(200), result.inspect

    result.dig('data', 'enrollment', 'ceAssessments')
  end

  describe 'enrollment ceAssessments query' do
    it 'returns CE assessments for the enrollment, sorted by assessment date by default' do
      assessments = perform_ce_assessments_query

      expect(assessments['nodesCount']).to eq(2)
      expect(assessments['nodes'].map { |assessment| assessment['id'] }).to eq(
        [
          newer_assessment.id.to_s,
          recently_updated_assessment.id.to_s,
        ],
      )
    end

    it 'supports sorting by date updated' do
      assessments = perform_ce_assessments_query(sort_order: 'DATE_UPDATED')

      expect(assessments['nodes'].map { |assessment| assessment['id'] }).to eq(
        [
          recently_updated_assessment.id.to_s,
          newer_assessment.id.to_s,
        ],
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
