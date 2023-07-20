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

  # Custom Integer field on Client (with no values, but should still be resolved)
  let!(:cded4) { create :hmis_custom_data_element_definition, label: 'A number', data_source: ds1, owner_type: 'Hmis::Hud::Client', field_type: :integer }

  before(:each) do
    hmis_login(user)
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
                                    a_hash_including(
                                      'key' => cded4.key,
                                      'label' => cded4.label,
                                      'value' => nil,
                                    ),
                                  ])
      end
    end
  end

  describe 'Service query' do
    include_context 'hmis service setup'
    # Set up service types (HUD and Custom)
    let(:hud_service_type) { Hmis::Hud::CustomServiceType.where(hud_record_type: 141).first }
    let!(:custom_service_type) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: csc1, name: 'some service' }

    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

    # Set up services (HUD and Custom)
    let!(:hud_service_1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, record_type: hud_service_type.hud_record_type, type_provided: hud_service_type.hud_type_provided }
    let!(:hud_service_2) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, record_type: 200, type_provided: 200 }
    let!(:custom_service_1) { create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, custom_service_type_id: custom_service_type.id }
    let!(:custom_service_2) { create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, custom_service_type_id: cst1.id }

    # Custom String field on specific HUD Service type
    let!(:cded_hud) { create :hmis_custom_data_element_definition, label: 'A string', data_source: ds1, owner_type: 'Hmis::Hud::Service', field_type: :string, custom_service_type_id: hud_service_type.id }
    # Custom Boolean field on specific Custom Service type
    let!(:cded_custom) { create :hmis_custom_data_element_definition, label: 'A boolean', repeats: true, data_source: ds1, owner_type: 'Hmis::Hud::CustomService', field_type: :boolean, custom_service_type_id: custom_service_type.id }

    let(:query) do
      <<~GRAPHQL
        query Service($id: ID!) {
          service(id: $id) {
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

    it 'resolves custom data elements on a HUD Service' do
      cded_hud_value = create(:hmis_custom_data_element, data_element_definition: cded_hud, owner: hud_service_1, data_source: ds1, value_string: 'foo')

      view_record = Hmis::Hud::HmisService.find_by(owner: hud_service_1)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to match([
                                    a_hash_including(
                                      'key' => cded_hud.key,
                                      'label' => cded_hud.label,
                                      'value' => a_hash_including('valueString' => cded_hud_value.value_string),
                                    ),
                                  ])
      end
    end

    it 'resolves custom data elements on a HUD Service even if they are not set' do
      view_record = Hmis::Hud::HmisService.find_by(owner: hud_service_1)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to match([
                                    a_hash_including(
                                      'key' => cded_hud.key,
                                      'label' => cded_hud.label,
                                      'value' => nil,
                                    ),
                                  ])
      end
    end

    it 'does not resolve custom data elements on a HUD Service of a different type' do
      view_record = Hmis::Hud::HmisService.find_by(owner: hud_service_2)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to be_empty
      end
    end

    it 'resolves custom data elements on a Custom Service' do
      cded_custom_value = create(:hmis_custom_data_element, data_element_definition: cded_custom, owner: custom_service_1, data_source: ds1, value_boolean: true)

      view_record = Hmis::Hud::HmisService.find_by(owner: custom_service_1)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to match([
                                    a_hash_including(
                                      'key' => cded_custom.key,
                                      'label' => cded_custom.label,
                                      'values' => [
                                        a_hash_including('valueBoolean' => cded_custom_value.value_boolean),
                                      ],
                                    ),
                                  ])
      end
    end

    it 'resolves custom data elements on a Custom Service even if they are not set' do
      view_record = Hmis::Hud::HmisService.find_by(owner: custom_service_1)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to match([
                                    a_hash_including(
                                      'key' => cded_custom.key,
                                      'label' => cded_custom.label,
                                      'values' => [],
                                    ),
                                  ])
      end
    end

    it 'does not resolve custom data elements on a Custom Service of a different type' do
      view_record = Hmis::Hud::HmisService.find_by(owner: custom_service_2)
      response, result = post_graphql(id: view_record.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'service', 'customDataElements')
        expect(elements).to be_empty
      end
    end
  end

  describe 'Assessments query' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:a1) { create :hmis_custom_assessment, data_source: ds1, enrollment: e1 }
    # define a custom field and set 2 values for it
    let!(:cded) { create :hmis_custom_data_element_definition, label: 'Special field', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment', field_type: :string, repeats: true }
    let!(:cde1) { create :hmis_custom_data_element, data_element_definition: cded, owner: a1, data_source: ds1, value_string: 'value 1' }
    let!(:cde2) { create :hmis_custom_data_element, data_element_definition: cded, owner: a1, data_source: ds1, value_string: 'value 2' }

    # this definition has no values
    let!(:cded2) { create :hmis_custom_data_element_definition, label: 'Another special field', data_source: ds1, owner_type: 'Hmis::Hud::CustomAssessment' }

    before(:each) do
      a1.save_not_in_progress
    end

    let(:query) do
      <<~GRAPHQL
        query Assessment($id: ID!) {
          assessment(id: $id) {
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
      response, result = post_graphql(id: a1.id) { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        elements = result.dig('data', 'assessment', 'customDataElements')
        expect(elements).to match_array([
                                          a_hash_including(
                                            'key' => cded.key,
                                            'label' => cded.label,
                                            'values' => [
                                              a_hash_including('valueString' => 'value 2'),
                                              a_hash_including('valueString' => 'value 1'),
                                            ],
                                          ),
                                          a_hash_including(
                                            'key' => cded2.key,
                                            'label' => cded2.label,
                                            'value' => nil,
                                          ),
                                        ])
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
