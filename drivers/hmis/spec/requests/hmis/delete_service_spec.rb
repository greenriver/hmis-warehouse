require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, user: u1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
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
            user{
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

  it 'should delete a service successfully' do
    response, result = post_graphql(id: s1.id) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      errors = result.dig('data', 'deleteService', 'errors')
      expect(errors).to be_empty
      expect(Hmis::Hud::Service.count).to eq(0)
    end
  end

  it 'should error if a service does not exist' do
    response, result = post_graphql(id: '0') { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      service = result.dig('data', 'deleteService', 'service')
      errors = result.dig('data', 'deleteService', 'errors')
      expect(service).to be_nil
      expect(errors).to contain_exactly(include('message' => 'Service record not found', 'attribute' => 'id'))
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
