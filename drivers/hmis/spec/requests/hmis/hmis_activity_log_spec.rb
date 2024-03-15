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

  let(:headers) do
    {
      'X-Hmis-Path' => '/path/x',
      'X-Hmis-Client-Id' => 123,
      'X-Hmis-Enrollment-Id' => 456,
      'X-Hmis-Project-Id' => 789,
    }
  end

  describe 'project resolver' do
    let(:operation_name) { 'getTestProject' }
    let(:project_query) do
      <<~GRAPHQL
        query #{operation_name}($projectId: ID!, $clientId: ID!) {
          client(id: $clientId) {
            id
            ssn
          }
          project(id: $projectId) {
            id
            projectName
            projectType
            organization {
              id
            }
          }
        }
      GRAPHQL
    end

    let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    before(:each) do
      create_access_control(hmis_user, p1)
      create_access_control(hmis_user, p2)
      hmis_login(user)
    end

    it 'should log a multiplexed query' do
      queries = [
        {
          query: project_query,
          variables: { 'projectId' => p1.id.to_s, 'clientId' => c1.id.to_s },
          operation_name: operation_name,
        },
        {
          query: project_query,
          variables: { 'projectId' => p2.id.to_s, 'clientId' => c1.id.to_s },
          operation_name: operation_name,
        },
      ]

      expect do
        response, _result = post_graphql_multi(queries: queries, headers: headers)
        expect(response.status).to eq 200
      end.to change(Hmis::ActivityLog, :count).by(2)

      queries.zip(Hmis::ActivityLog.order(:id).last(2)).each do |query, log|
        check_log(
          log,
          user: user,
          variables: query[:variables],
          operation_name: query[:operation_name],
          headers: headers,
        )
        check_project_fields(
          log,
          project_id: query.dig(:variables, 'projectId'),
          client_id: query.dig(:variables, 'clientId'),
        )
      end
    end

    it 'should log a single query' do
      variables = { 'projectId' => p1.id.to_s, 'clientId' => c1.id.to_s }
      expect do
        response, _result = post_graphql_single(variables: variables, headers: headers, operation_name: operation_name, query: project_query)
        expect(response.status).to eq 200
      end.to change(Hmis::ActivityLog, :count).by(1)

      log = Hmis::ActivityLog.order(:id).last
      check_log(log, user: user, variables: variables, operation_name: operation_name, headers: headers)
      check_project_fields(log, project_id: p1.id, client_id: c1.id)
    end
  end

  describe 'access resolver' do
    let(:operation_name) { 'getTestProject' }
    before(:each) do
      hmis_login(user)
    end
    let(:access_query) do
      <<~GRAPHQL
        query #{operation_name}{
          access {
            id
            canAdministerHmis
            canEditClients
            __typename
          }
        }
      GRAPHQL
    end

    it 'should log queries' do
      expect do
        response, _result = post_graphql_single(headers: headers, operation_name: operation_name, query: access_query)
        expect(response.status).to eq 200
      end.to change(Hmis::ActivityLog, :count).by(1)

      log = Hmis::ActivityLog.order(:id).last
      check_log(log, user: user, operation_name: operation_name, headers: headers)
    end
  end

  def check_log(log, user:, variables: nil, operation_name:, headers:)
    expect(log.user_id).to eq(user.id)
    expect(log.ip_address).to eq('127.0.0.1')
    expect(log.variables).to eq(variables)
    expect(log.operation_name).to eq(operation_name)
    expect(log.header_page_path).to eq(headers['X-Hmis-Path'])
    expect(log.header_client_id).to eq(headers['X-Hmis-Client-Id'])
    expect(log.header_enrollment_id).to eq(headers['X-Hmis-Enrollment-Id'])
    expect(log.header_project_id).to eq(headers['X-Hmis-Project-Id'])
    expect(log.response_time).to be > 0
    expect(log.response_time).to be < 2
  end

  def check_project_fields(log, project_id:, client_id:)
    project = Hmis::Hud::Project.find(project_id)
    organization = project.organization
    expect(log.resolved_fields).to eq(
      {
        "Project/#{project.id}" => [],
        "Organization/#{organization.id}" => [],
        "Client/#{client_id}" => ['ssn'],
      },
    )
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
