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

  before(:each) do
    hmis_login(user)
  end

  describe 'TableConfigLookup' do
    describe 'ceClientsGlobalConfig' do
      let(:query) do
        <<~GRAPHQL
          query TableConfigLookup {
            tableConfigLookup {
              ceClientsGlobalConfig {
                columns {
                  key
                  label
                  type
                }
                filters {
                  key
                  label
                  options {
                    code
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      context 'when no global config exists' do
        it 'returns null' do
          response, result = post_graphql({}) { query }

          aggregate_failures 'checking response' do
            expect(response.status).to eq(200), result.inspect
            config = result.dig('data', 'tableConfigLookup', 'ceClientsGlobalConfig')
            expect(config).to be_nil
          end
        end
      end

      context 'when global config exists' do
        let!(:global_config) do
          create(
            :hmis_table_configuration_ce_clients,
            :with_columns,
            :with_filters,
            data_source: ds1,
            owner: nil,
          )
        end

        it 'returns the global configuration' do
          response, result = post_graphql({}) { query }

          aggregate_failures 'checking response' do
            expect(response.status).to eq(200), result.inspect
            config = result.dig('data', 'tableConfigLookup', 'ceClientsGlobalConfig')
            expect(config).to be_present

            # Check columns
            expect(config['columns']).to be_present
            column = config['columns'].first
            expect(column).to include(
              'key' => 'cde.custom_assessment.my_household_type',
              'type' => 'STRING',
              'label' => 'Household Type',
            )

            # Check filters
            expect(config['filters']).to be_present
            filter = config['filters'].first
            expect(filter).to include(
              'key' => 'cde.custom_assessment.my_household_type',
              'label' => 'Household Type',
            )
            expect(filter['options']).to contain_exactly(
              { 'code' => 'Household with children' },
              { 'code' => 'Household without children' },
            )
          end
        end
      end
    end

    describe 'ceClientsUnitGroupConfig' do
      let!(:organization) { create :hmis_hud_organization, data_source: ds1 }
      let!(:project) { create :hmis_hud_project, data_source: ds1, organization: organization }
      let!(:unit_group) { create :hmis_unit_group, project: project, name: 'Test Unit Group' }

      let(:query) do
        <<~GRAPHQL
          query TableConfigLookup($unitGroupId: ID!) {
            tableConfigLookup {
              ceClientsUnitGroupConfig(unitGroupId: $unitGroupId) {
                columns {
                  key
                  label
                  type
                }
                filters {
                  key
                  label
                  options {
                    code
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      context 'when unit group has no applicable config' do
        it 'returns null' do
          response, result = post_graphql({ unit_group_id: unit_group.id }) { query }

          aggregate_failures 'checking response' do
            expect(response.status).to eq(200), result.inspect
            config = result.dig('data', 'tableConfigLookup', 'ceClientsUnitGroupConfig')
            expect(config).to be_nil
          end
        end
      end

      context 'when unit group has config' do
        let!(:unit_group_config) do
          create(
            :hmis_table_configuration_ce_clients,
            :with_columns,
            :with_filters,
            data_source: ds1,
            owner: unit_group,
          )
        end

        it 'returns the unit group configuration' do
          response, result = post_graphql({ unit_group_id: unit_group.id }) { query }

          aggregate_failures 'checking response' do
            expect(response.status).to eq(200), result.inspect
            config = result.dig('data', 'tableConfigLookup', 'ceClientsUnitGroupConfig')
            expect(config).to be_present

            # Check columns
            expect(config['columns']).to be_present
            column = config['columns'].first
            expect(column).to include(
              'key' => 'cde.custom_assessment.my_household_type',
              'type' => 'STRING',
              'label' => 'Household Type',
            )

            # Check filters
            expect(config['filters']).to be_present
            filter = config['filters'].first
            expect(filter).to include(
              'key' => 'cde.custom_assessment.my_household_type',
              'label' => 'Household Type',
            )
            expect(filter['options']).to contain_exactly(
              { 'code' => 'Household with children' },
              { 'code' => 'Household without children' },
            )
          end
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
