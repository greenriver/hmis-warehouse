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
      mutation CreateClientAlert($id: ID!, $note: String!, $expirationDate: ISO8601Date, $priority: ClientAlertPriorityLevel) {
        createClientAlert(id: $id, note: $note, expirationDate: $expirationDate, priority: $priority) {
          clientAlert {
            id
            note
            priority
            expirationDate
            createdBy { id }
            createdAt
          }
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

    it 'should successfully create an alert' do
      response, result = post_graphql(
        id: c1.id,
        note: 'raspberries',
        priority: 'high',
        expirationDate: Date.current + 2.months,
      ) { create_alert }
      expect(response.status).to eq(200), result.inspect
      alert = result.dig('data', 'createClientAlert', 'clientAlert')
      expect(alert).not_to be_nil
      expect(alert['note']).to eq('raspberries')
      expect(alert['priority']).to eq('high')
      expect(Date.parse(alert['expirationDate'])).to eq((Date.current + 2.months))
      expect(alert.dig('createdBy', 'id')).to eq(hmis_user.id.to_s)
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
      expect_gql_error post_graphql(id: c1.id, note: 'strawberries') { create_alert }
      expect(c1.alerts.size).to eq(2), 'a third alert should not have been created'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
