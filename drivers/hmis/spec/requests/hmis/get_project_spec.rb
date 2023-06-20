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
  let!(:access_control) { create_access_control(hmis_user, p1) }
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
    end

    it 'should resolve invalid enum values as INVALID enum' do
      p1.update(project_type: 300)
      p1.update(housing_type: 300)
      p1.update(tracking_method: 300)
      p1.update(residential_affiliation: 50)
      p1.update(continuum_project: 50)

      aggregate_failures 'checking response' do
        response, result = post_graphql({ id: p1.id }) { query }
        expect(response.status).to eq 200
        project = result.dig('data', 'project')
        expect(project).to include(
          'id' => p1.id.to_s,
          'projectType' => 'INVALID',
          'housingType' => 'INVALID',
          'trackingMethod' => 'INVALID',
          'residentialAffiliation' => 'INVALID',
          'continuumProject' => 'INVALID',
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
