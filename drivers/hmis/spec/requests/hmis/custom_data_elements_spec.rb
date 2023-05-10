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

  # Custom String field on Project (repeating with 2 values)
  let!(:cded1) { create :hmis_custom_data_element_definition, label: 'Multiple strings', data_source: ds1, owner_type: 'Hmis::Hud::Project', repeats: true }
  let!(:cde1a) { create :hmis_custom_data_element, data_element_definition: cded1, owner: p1, data_source: ds1, value_string: 'First value' }
  let!(:cde1b) { create :hmis_custom_data_element, data_element_definition: cded1, owner: p1, data_source: ds1, value_string: 'Second value' }

  # Custom Boolean field on Client (repeating with 1 value)
  let!(:cded2) { create :hmis_custom_data_element_definition, label: 'Multiple booleans', data_source: ds1, owner_type: 'Hmis::Hud::Client', field_type: :boolean, repeats: true }
  let!(:cde2) { create :hmis_custom_data_element, data_element_definition: cded2, owner: c1, data_source: ds1, value_boolean: true }

  # Custom JSON field on Client (non-repeating)
  let!(:cded3) { create :hmis_custom_data_element_definition, label: 'One json', data_source: ds1, owner_type: 'Hmis::Hud::Client', field_type: :json }
  let!(:cde3) { create :hmis_custom_data_element, data_element_definition: cded3, owner: c1, data_source: ds1, value_json: { foo: 'bar' }.to_json }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  describe 'Project query' do
    let(:query) do
      <<~GRAPHQL
        query Project($id: ID!) {
          project(id: $id) {
            id
            customDataElements {
              #{scalar_fields(Types::HmisSchema::CustomDataElement)}
              value {
                #{scalar_fields(Types::HmisSchema::CustomDataElementValue)}
              }
              values {
                #{scalar_fields(Types::HmisSchema::CustomDataElementValue)}
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves custom data elements' do
      response, result = post_graphql(id: p1.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'project', 'customDataElements')
        expect(elements).to match([
                                    a_hash_including(
                                      'key' => cded1.key,
                                      'label' => cded1.label,
                                      'values' => [
                                        a_hash_including('valueString' => cde1a.value_string),
                                        a_hash_including('valueString' => cde1b.value_string),
                                      ],
                                    ),
                                  ])
      end
    end

    describe 'Client query' do
      let(:query) do
        <<~GRAPHQL
          query Client($id: ID!) {
            client(id: $id) {
              id
              customDataElements {
                #{scalar_fields(Types::HmisSchema::CustomDataElement)}
                value {
                  #{scalar_fields(Types::HmisSchema::CustomDataElementValue)}
                }
                values {
                  #{scalar_fields(Types::HmisSchema::CustomDataElementValue)}
                }
              }
            }
          }
        GRAPHQL
      end

      it 'resolves custom data elements' do
        response, result = post_graphql(id: c1.id) { query }
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          elements = result.dig('data', 'client', 'customDataElements')
          expect(elements).to match([
                                      a_hash_including(
                                        'key' => cded2.key,
                                        'label' => cded2.label,
                                        'values' => [
                                          a_hash_including('valueBoolean' => cde2.value_boolean),
                                        ],
                                      ),
                                      a_hash_including(
                                        'key' => cded3.key,
                                        'label' => cded3.label,
                                        'value' => a_hash_including('valueJson' => cde3.value_json),
                                      ),
                                    ])
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
