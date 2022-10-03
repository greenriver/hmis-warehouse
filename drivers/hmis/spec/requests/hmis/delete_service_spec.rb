require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let!(:ds1) { create :source_data_source, hmis: GraphqlHelpers::HMIS_HOSTNAME }
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let!(:p1) { create :hmis_hud_project, data_source_id: ds1.id, organization: o1 }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1 }
  let!(:s1) { create :hmis_hud_service, data_source_id: ds1.id, client: c1, enrollment: e1 }

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })

    @hmis_user = Hmis::User.find(user.id)
    @hmis_user.hmis_data_source_id = ds1.id
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteService($id: ID!) {
        deleteService(input: { id: $id }) {
          service {
            id
            enrollment {
              id
            }
            client {
              id
            }
            dateProvided
            recordType
            typeProvided
            subTypeProvided
            otherTypeProvided
            movingOnOtherType
            FAAmount
            referralOutcome
          }
          errors {
            attribute
            message
            fullMessage
            type
            options
            __typename
          }
        }
      }
    GRAPHQL
  end

  it 'should create a service successfully' do
    response, result = post_graphql(id: s1.id) { mutation }

    expect(response.status).to eq 200
    errors = result.dig('data', 'deleteService', 'errors')
    expect(errors).to be_empty
    expect(Hmis::Hud::Service.count).to eq(0)
  end

  it 'should error if a service does not exist' do
    response, result = post_graphql(id: '0') { mutation }

    expect(response.status).to eq 200
    service = result.dig('data', 'deleteService', 'service')
    errors = result.dig('data', 'deleteService', 'errors')
    expect(service).to be_nil
    expect(errors).to contain_exactly(include('message' => "No service found with ID '0'", 'attribute' => 'id'))
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
