###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }

  # Enrollments at p1 (2 open, 1 closed)
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:e1_dup) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, exit_date: 1.week.ago }

  let!(:p2) { create :hmis_hud_project, data_source: ds1 }
  # Enrollments at p2 (1 open, 1 closed)
  let!(:e3) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p2, client: c1 }
  let!(:e4) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, exit_date: 1.week.ago }

  let!(:p3) { create :hmis_hud_project, data_source: ds1, confidential: true }
  # Enrollments at p3 (1 open, confidential)
  let!(:e5) { create :hmis_hud_enrollment, data_source: ds1, project: p3, client: c1 }

  # canary values
  let!(:e6) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:e7) { create :hmis_hud_enrollment, data_source: ds1, project: p2 }

  # Give user full access to p1
  let!(:access_control) { create_access_control(hmis_user, p1) }
  # Give user some limited access to p3
  let!(:access_control2) { create_access_control(hmis_user, p3, with_permission: :can_view_clients) }

  before(:each) do
    hmis_login(user)
  end

  describe 'Open enrollment summary' do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($id: ID!) {
          enrollment(id: $id) {
            id
            openEnrollmentSummary {
              id
              entryDate
              projectName
              canViewEnrollment
            }
          }
        }
      GRAPHQL
    end

    def perform_query(id = e1.id)
      response, result = post_graphql(id: id) { query }
      expect(response.status).to eq(200), result.inspect
      enrollment = result.dig('data', 'enrollment')
      expect(enrollment['id']).to be_present
      result.dig('data', 'enrollment', 'openEnrollmentSummary')
    end

    it 'resolves nothing if user does not have permission' do
      remove_permissions(access_control, :can_view_open_enrollment_summary)
      results = perform_query
      expect(results).to be_empty
    end

    it 'resolves correct enrollment summary' do
      results = perform_query
      expect(results).to contain_exactly(
        a_hash_including('id' => e1_dup.id.to_s, 'projectName' => p1.project_name, 'canViewEnrollment' => true),
        a_hash_including('id' => e3.id.to_s, 'projectName' => p2.project_name, 'canViewEnrollment' => false),
        a_hash_including('id' => e5.id.to_s, 'projectName' => Hmis::Hud::Project::CONFIDENTIAL_PROJECT_NAME, 'canViewEnrollment' => false),
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
