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

  let(:query) do
    <<~GRAPHQL
      query GetProject($id: ID!) {
        project(id: $id) {
          #{scalar_fields(Types::HmisSchema::Project)}
          organization {
            id
          }
        }
      }
    GRAPHQL
  end

  describe 'project query' do
    before(:each) do
      hmis_login(user)
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
    end

    it 'should resolve invalid enum values as INVALID enum' do
      p1.update(project_type: 300)
      p1.update(housing_type: 300)
      p1.update(tracking_method: 300)

      aggregate_failures 'checking response' do
        response, result = post_graphql({ id: p1.id }) { query }
        expect(response.status).to eq 200
        project = result.dig('data', 'project')
        expect(project).to include(
          'id' => p1.id.to_s,
          'projectType' => 'INVALID',
          'housingType' => 'INVALID',
          'trackingMethod' => 'INVALID',
        )
      end
    end

    it 'should resolve invalid NoYesMissing values as nil' do
      p1.update(residential_affiliation: 50)
      p1.update(continuum_project: 50)

      aggregate_failures 'checking response' do
        response, result = post_graphql({ id: p1.id }) { query }
        expect(response.status).to eq 200
        project = result.dig('data', 'project')
        expect(project).to include(
          'id' => p1.id.to_s,
          'residentialAffiliation' => nil,
          'continuumProject' => nil,
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
