###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:id1_retired1) { create :hmis_form_definition, identifier: 'identifier_1', version: 0, status: 'retired', title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_retired2) { create :hmis_form_definition, identifier: 'identifier_1', version: 1, status: 'retired', title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_published) { create :hmis_form_definition, identifier: 'identifier_1', version: 2, status: 'published', title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_draft) { create :hmis_form_definition, identifier: 'identifier_1', version: 3, status: 'draft', title: 'The title of this assessment has changed!', role: 'CUSTOM_ASSESSMENT' }

  before(:each) do
    hmis_login(user)
  end

  describe 'Form identifier query' do
    let(:query) do
      <<~GRAPHQL
        query GetFormIdentifiers(
          $limit: Int = 25
          $offset: Int = 0
          $filters: FormIdentifierFilterOptions
        ) {
          formIdentifiers(limit: $limit, offset: $offset, filters: $filters) {
            offset
            limit
            nodesCount
            nodes {
              identifier
              role
              title
              representativeVersion {
                ...FormDefinitionMetadata
              }
              draft {
                ...FormDefinitionMetadata
              }
              retiredVersions {
                nodesCount
              }
            }
          }
        }
        fragment FormDefinitionMetadata on FormDefinition {
          id
          role
          title
          cacheKey
          identifier
        }
      GRAPHQL
    end

    it 'should return form definition identifiers' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
      identifiers = result.dig('data', 'formIdentifiers', 'nodes')
      expect(identifiers).to be_present
      expect(identifiers.first['identifier']).to eq('identifier_1')
      expect(identifiers.first['role']).to eq('CUSTOM_ASSESSMENT')
      expect(identifiers.first['title']).to eq('This is an assessment!')
      expect(identifiers.first.dig('draft', 'title')).to eq('The title of this assessment has changed!')
      expect(identifiers.first['retiredVersions']['nodesCount']).to eq(2)
    end

    it 'should filter correctly' do
      response, result = post_graphql(filters: { search_term: 'identifier_1' }) { query }
      expect(response.status).to eq(200), result.inspect
      identifiers = result.dig('data', 'formIdentifiers', 'nodes')
      expect(identifiers.count).to eq(1)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
