###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  describe 'enrollment resolver' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 1.week.ago }

    # CurrentLivingSituation
    let!(:cls) { create(:hmis_current_living_situation, client: c1, enrollment: e1, data_source: ds1) }
    # ClientLocationHistory::Location that has Enrollment as a source
    let!(:cls_location) { create(:clh_location, source: e1.as_warehouse, client_id: c1.id, collected_by: p1.project_name, located_on: 1.week.ago) }
    # FormProcessor linking together the CLS and the Location
    let!(:cls_form_processor) { create(:hmis_form_processor, owner: cls, clh_location: cls_location) }

    # CustomAssessment
    let!(:assessment) { create(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1) }
    # ClientLocationHistory::Location that has Enrollment as a source
    let!(:assessment_location) { create(:clh_location, source: e1.as_warehouse, client_id: c1.id, collected_by: p1.project_name, located_on: 1.month.ago) }
    # FormProcessor linking together the CustomAssessment and the Location
    let!(:assessment_form_processor) { assessment.form_processor.update!(clh_location: assessment_location) }

    let(:query) do
      <<~GRAPHQL
        query getEnrollment($id: ID!) {
          enrollment(id: $id) {
            id
            geolocations {
              id
              collectedByProjectName
              coordinates {
                latitude
                longitude
              }
              sourceCurrentLivingSituation {
                id
              }
              sourceAssessment {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    before(:each) do
      hmis_login(user)
    end

    def perform_mutation(enrollment_id: e1.id)
      response, result = post_graphql(id: enrollment_id) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'enrollment', 'geolocations')
    end

    context 'when user lacks permission to view locations' do
      let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_view_enrollment_location_map) }

      it 'does not resolve locations' do
        locations = perform_mutation

        expect(locations).to be_empty
      end
    end
    context 'when user has permission to view locations' do
      let!(:access_control) { create_access_control(hmis_user, p1) }

      it 'resolves locations' do
        locations = perform_mutation

        expect(locations).to contain_exactly(
          a_hash_including('id' => cls_location.id.to_s, 'sourceCurrentLivingSituation' => a_hash_including('id' => cls.id.to_s)),
          a_hash_including('id' => assessment_location.id.to_s, 'sourceAssessment' => a_hash_including('id' => assessment.id.to_s)),
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
