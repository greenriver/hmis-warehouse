###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:o2) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o2, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e3) do
    e = create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1
    e.save_in_progress
    e
  end
  let(:c2) { create :hmis_hud_client, dob: Date.today - 1.year, data_source: ds1, user: u1 }

  let!(:csc) { create(:hmis_custom_service_category, name: 'ESG Funding Assistance', data_source: ds1, user: u1) }
  let!(:cst) { create(:hmis_custom_service_type, name: 'ESG Funding Assistance', custom_service_category: csc, data_source: ds1, user: u1) }
  let!(:cst2) { create(:hmis_custom_service_type, name: 'Other Service', custom_service_category: csc, data_source: ds1, user: u1) }
  let!(:cs1) { create(:hmis_custom_service, client: c1, enrollment: e1, custom_service_type: cst, data_source: ds1, user: u1) }
  let!(:cs2) { create(:hmis_custom_service, client: c1, enrollment: e2, custom_service_type: cst, data_source: ds1, user: u1) }
  let!(:cs3) { create(:hmis_custom_service, client: c1, enrollment: e1, custom_service_type: cst2, data_source: ds1, user: u1) }
  let!(:cs4) { create(:hmis_custom_service, client: c2, enrollment: e1, custom_service_type: cst, data_source: ds1, user: u1) }
  let!(:cs5) { create(:hmis_custom_service, client: c1, enrollment: e3, custom_service_type: cst, data_source: ds1, user: u1) }

  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:query) do
    <<~GRAPHQL
      query GetEsgFundingReport($clientIds: [ID!]!) {
        esgFundingReport(clientIds: $clientIds) {
          esgFundingServices {
            id
            clientId
            clientDob
            mciIds {
              id
              identifier
              label
              url
            }
            firstName
            lastName
            projectId
            projectName
            organizationId
            organizationName
            faAmount
            faStartDate
            faEndDate
            customDataElements {
              id
              key
              label
              repeats
              value {
                id
                valueBoolean
                valueDate
                valueFloat
                valueInteger
                valueJson
                valueString
                valueText
              }
              values {
                id
                valueBoolean
                valueDate
                valueFloat
                valueInteger
                valueJson
                valueString
                valueText
              }
            }
          }
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  it 'should resolve funding report correctly' do
    # ensure cs2 is not viewable to the user
    expect(Hmis::Hud::CustomService.viewable_by(hmis_user).exists?(cs2.id)).to eq(false)
    # ensure client has services other than ESG Funding Assistance
    expect(Hmis::Hud::CustomService.all).to include(have_attributes(id: cs3.id, service_name: cst2.name))
    # ensure client ages will test right
    expect(Hmis::Hud::Client.older_than(18, or_equal: true).exists?(c1.id)).to be_truthy
    expect(Hmis::Hud::Client.older_than(18, or_equal: true).exists?(c2.id)).to be_falsy
    # ensure WIP enrollment
    expect(Hmis::Hud::Enrollment.in_progress.exists?(e3.id)).to be_truthy

    aggregate_failures 'checking response' do
      response, result = post_graphql({ client_ids: [c1.id.to_s, c2.id.to_s] }) { query }
      expect(response.status).to eq 200
      expect(result.dig('data', 'esgFundingReport', 'esgFundingServices')).to contain_exactly(
        # show cs1: viewable, is the right custom service type, and 18+
        include('id' => cs1.id.to_s, 'clientId' => c1.id.to_s, 'projectId' => p1.project_id),
        # show cs2: not viewable, is right service type, and is 18+
        include('id' => cs2.id.to_s, 'clientId' => c1.id.to_s, 'projectId' => p2.project_id),
        # don't show cs3: not the right service type
        # don't show cs4: not 18+
        # show cs5: viewable, right type, 18+, with WIP enrollment
        include('id' => cs5.id.to_s, 'clientId' => c1.id.to_s, 'projectId' => p1.project_id),
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
