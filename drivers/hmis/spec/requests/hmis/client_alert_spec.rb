#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

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

  before(:each) do
    hmis_login(user)
  end

  include_context 'hmis base setup'

  let(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          alerts {
            id
            note
          }
        }
      }
    GRAPHQL
  end

  let(:create_alert) do
    <<~GRAPHQL
      mutation CreateClientAlert($input: ClientAlertInput!) {
        createClientAlert(input: $input) {
          clientAlert {
            id
            note
            priority
            expirationDate
            createdBy { id }
            createdAt
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:a1) { create :hmis_client_alert, created_by: hmis_user, client: c1, note: 'bananas' }
  let!(:a2) { create :hmis_client_alert, created_by: hmis_user, client: c1, note: 'pears' }

  describe 'when the user has full access' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'should return the client with an alert' do
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq(200), result.inspect
      alerts = result.dig('data', 'client', 'alerts')
      expect(alerts.size).to eq 2
      expect(alerts[0]['note']).to eq('pears'), 'Results should be in descending order by creation time'
      expect(alerts[1]['note']).to eq('bananas')
    end

    it 'should not return expired alerts' do
      a1 = Hmis::ClientAlert.first
      a1.expiration_date = Date.current - 10.days
      a1.save!
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq(200), result.inspect
      alerts = result.dig('data', 'client', 'alerts')
      expect(alerts.size).to eq 1
      expect(alerts[0]['note']).to eq('pears')
    end

    it 'should successfully create an alert' do
      mutation_input = { id: c1.id.to_s, note: 'raspberries', priority: 'high', expirationDate: Date.current + 2.months }
      response, result = post_graphql(input: mutation_input) { create_alert }
      expect(response.status).to eq(200), result.inspect
      alert_id = result.dig('data', 'createClientAlert', 'clientAlert', 'id')
      expect(alert_id).not_to be_nil
      alert = Hmis::ClientAlert.find(alert_id)
      expect(alert.note).to eq('raspberries')
      expect(alert.priority).to eq(Hmis::ClientAlert::HIGH)
      expect(alert.expiration_date).to eq((Date.current + 2.months))
      expect(alert.created_by.id).to eq(hmis_user.id)
    end
  end

  describe 'when the user does not have permission to view client alerts' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: [:can_view_client_alerts, :can_manage_client_alerts]) }

    it 'should return a client, but without any alerts' do
      response, result = post_graphql(id: c1.id) { query }
      expect(response.status).to eq(200), result.inspect
      alerts = result.dig('data', 'client', 'alerts')
      expect(alerts).not_to be_nil
      expect(alerts).to be_empty
    end

    it 'should not be able to create alerts either' do
      mutation_input = { id: c1.id.to_s, note: 'errr' }
      # expect_gql_error post_graphql(input: mutation_input) { create_alert }
      response, result = post_graphql(input: mutation_input) { create_alert }
      expect(response).to eq(200) # TODO @martha pr - this is from default_create_record
      err = result.dig('data', 'createClientAlert', 'errors')
      expect(err.size).to eq(1)
      expect(err[0]['message']).to eq('operation not allowed')
      expect(c1.alerts.size).to eq(2), 'a third alert should not have been created'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
