# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

# Mirrors defaults in drivers/hmis/app/graphql/hmis_schema.rb (update when those change).
HMIS_SCHEMA_DEFAULT_MAX_DEPTH = 30
HMIS_SCHEMA_DEFAULT_MAX_COMPLEXITY = 1_500

RSpec.describe HmisSchema, 'depth and complexity limits', type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, p1) }

  # Build a nested project query
  def build_nested_project_query(cycles)
    inner = 'id'
    cycles.times do
      inner = "organization { projects(limit: 1) { nodes { #{inner} } } }"
    end
    <<~GRAPHQL
      query TestQuery($id: ID!) {
        project(id: $id) {
          #{inner}
        }
      }
    GRAPHQL
  end

  # Build a complex root query using field aliases
  def build_high_complexity_root_query(field_count)
    fields = field_count.times.map { |i| "f#{i}: __typename" }.join("\n")
    <<~GRAPHQL
      query {
        #{fields}
      }
    GRAPHQL
  end

  context 'HmisSchema.execute' do
    let(:graphql_context) do
      {
        current_user: hmis_user,
        true_user: hmis_user,
        activity_logger: Hmis::GraphqlFieldLogger.new,
      }
    end

    it 'allows a normal shallow project query under default limits' do
      query = <<~GRAPHQL
        query TestQuery($id: ID!) {
          project(id: $id) {
            id
            organization { id }
          }
        }
      GRAPHQL
      result = HmisSchema.execute(
        query,
        variables: { 'id' => p1.id.to_s },
        context: graphql_context,
      )
      expect(result['errors']).to be_blank
      expect(result.dig('data', 'project', 'id')).to eq(p1.id.to_s)
    end

    it 'rejects queries that exceed max_depth before execution' do
      query = build_nested_project_query(3)
      result = HmisSchema.execute(
        query,
        variables: { 'id' => p1.id.to_s },
        context: graphql_context,
        max_depth: 10,
      )
      expect(result['errors']).to be_present
      expect(result['errors'].first['message']).to match(/depth/i)
      expect(result['data']).to be_nil
    end

    it 'rejects queries that exceed max_complexity before execution' do
      query = build_high_complexity_root_query(50)
      result = HmisSchema.execute(
        query,
        context: graphql_context,
        max_complexity: 10,
      )
      expect(result['errors']).to be_present
      expect(result['errors'].first['message']).to match(/complexity/i)
      expect(result['data']).to be_nil
    end

    it 'rejects pathological depth against schema default max_depth' do
      # Nested enough to exceed HMIS_SCHEMA_DEFAULT_MAX_DEPTH
      query = build_nested_project_query(10)
      result = HmisSchema.execute(
        query,
        variables: { 'id' => p1.id.to_s },
        context: graphql_context,
      )
      expect(result['errors']).to be_present
      expect(result['errors'].first['message']).to match(/depth/i)
    end
  end

  context 'POST /hmis/hmis-gql' do
    include GraphqlHelpers

    before(:each) do
      hmis_login(user)
    end

    it 'raises on query that exceeds max_depth' do
      query = build_nested_project_query(10)
      expect do
        post_graphql(id: p1.id) { query }
      end.to raise_error(RuntimeError, /depth/i)
    end

    it 'raises on query that exceeds max_complexity' do
      # Default max_complexity is 1_500; each root __typename alias costs ~1 toward the total.
      query = build_high_complexity_root_query(HMIS_SCHEMA_DEFAULT_MAX_COMPLEXITY + 100)
      expect do
        post_graphql(id: p1.id) { query }
      end.to raise_error(RuntimeError, /complexity/i)
    end
  end
end
