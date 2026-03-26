###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:id1_retired1) { create :hmis_form_definition, identifier: 'identifier_1', version: 0, status: Hmis::Form::Definition::RETIRED, title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_retired2) { create :hmis_form_definition, identifier: 'identifier_1', version: 1, status: Hmis::Form::Definition::RETIRED, title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_published) { create :hmis_form_definition, identifier: 'identifier_1', version: 2, status: Hmis::Form::Definition::PUBLISHED, title: 'This is an assessment!', role: 'CUSTOM_ASSESSMENT' }
  let!(:id1_draft) { create :hmis_form_definition, identifier: 'identifier_1', version: 3, status: Hmis::Form::Definition::DRAFT, title: 'The title of this assessment has changed!', role: 'CUSTOM_ASSESSMENT' }

  before(:each) do
    hmis_login(user)
  end

  describe 'Form identifiers query' do
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
              id
              identifier
              publishedVersion {
                ...FormDefinitionMetadata
              }
              draftVersion {
                ...FormDefinitionMetadata
              }
              displayVersion {
                ...FormDefinitionMetadata
              }
              allVersions {
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
      expect(identifiers.first.dig('displayVersion', 'role')).to eq('CUSTOM_ASSESSMENT')
      expect(identifiers.first.dig('displayVersion', 'title')).to eq('This is an assessment!')
      expect(identifiers.first.dig('publishedVersion', 'title')).to eq('This is an assessment!')
      expect(identifiers.first.dig('draftVersion', 'title')).to eq('The title of this assessment has changed!')
      expect(identifiers.first['allVersions']['nodesCount']).to eq(4)
    end

    it 'should filter correctly' do
      response, result = post_graphql(filters: { search_term: 'identifier_1' }) { query }
      expect(response.status).to eq(200), result.inspect
      identifiers = result.dig('data', 'formIdentifiers', 'nodes')
      expect(identifiers.count).to eq(1)
    end
  end

  describe 'Form identifier query' do
    let(:query) do
      <<~GRAPHQL
        query GetFormIdentifier($identifier: String!) {
          formIdentifier(identifier: $identifier) {
            id
            identifier
            publishedVersion {
              id
            }
            draftVersion {
              id
            }
            allVersions {
              nodesCount
            }
          }
        }
      GRAPHQL
    end

    it 'returns the form identifier for the given identifier (latest version per identifier, same shape as formIdentifiers)' do
      response, result = post_graphql(identifier: 'identifier_1') { query }
      expect(response.status).to eq(200), result.inspect
      node = result.dig('data', 'formIdentifier')
      expect(node).to be_present
      expect(node['identifier']).to eq('identifier_1')
      expect(node.dig('publishedVersion', 'id')).to eq(id1_published.id.to_s)
      expect(node.dig('draftVersion', 'id')).to eq(id1_draft.id.to_s)
      expect(node['allVersions']['nodesCount']).to eq(4)
    end

    it 'returns null when the identifier does not exist' do
      response, result = post_graphql(identifier: 'no_such_identifier') { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'formIdentifier')).to be_nil
    end

    it 'returns null for admin-only form roles when user lacks can_administrate_config' do
      create(
        :hmis_form_definition,
        identifier: 'external_form_identifier',
        version: 1,
        status: Hmis::Form::Definition::PUBLISHED,
        title: 'External form',
        role: 'EXTERNAL_FORM',
      )
      remove_permissions(access_control, :can_administrate_config)
      response, result = post_graphql(identifier: 'external_form_identifier') { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'formIdentifier')).to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
