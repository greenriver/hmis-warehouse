require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:test_input) do
    {
      first_name: 'John',
      last_name: 'Smith',
      middle_name: 'Joseph',
      preferred_name: 'Johnny',
      name_suffix: 'jr',
      name_data_quality: 1,
      dob: '2022-06-15',
      dob_data_quality: 2,
      ssn: '123-45-6789',
      ssn_data_quality: 3,
      ethnicity: 1,
      veteran_status: 1,
      gender: [0],
      race: ['AmIndAKNative'],
    }
  end

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  describe 'Client input transformer' do
    let(:transformer) { Types::HmisSchema::Transformers::ClientInputTransformer }

    it 'transforms basic fields' do
      input = OpenStruct.new(test_input.except(:race, :gender))
      result = transformer.new(input).to_params

      expect(result).to eq(
        {
          'DOB' => input.dob,
          'DOBDataQuality' => input.dob_data_quality,
          'Ethnicity' => input.ethnicity,
          'FirstName' => input.first_name,
          'LastName' => input.last_name,
          'MiddleName' => input.middle_name,
          'NameDataQuality' => input.name_data_quality,
          'NameSuffix' => input.name_suffix,
          'SSN' => input.ssn.gsub(/\D+/, ''),
          'SSNDataQuality' => input.ssn_data_quality,
          'VeteranStatus' => input.veteran_status,
          'preferred_name' => input.preferred_name,
        },
      )
    end

    [
      [:gender, Hmis::Hud::Client.gender_enum_map, 'Data not collected', :GenderNone],
      [:race, Hmis::Hud::Client.race_enum_map, :not_collected, :RaceNone],
    ].each do |field, enum_map, not_collected_key, none_field|
      describe "when transforming #{field}" do
        it 'should set fields as expected when non-null values are provided' do
          value = test_input[field].first
          client_column = enum_map.lookup(value: value)[:key]
          input = OpenStruct.new(test_input.slice(field))

          result = transformer.new(input).to_params

          expect(result).to include(
            none_field => nil,
            **enum_map.base_members.map do |member|
              client_attr = member[:key]
              [client_attr, client_attr == client_column ? 1 : 0]
            end.to_h,
          )
        end

        it 'should set fields as expected when a null value is provided' do
          value = enum_map.null_members.first[:value]
          not_collected_value = enum_map.lookup(key: not_collected_key)[:value]
          input = OpenStruct.new(field => [value])

          result = transformer.new(input).to_params

          expect(result).to include(
            {
              none_field => value,
              **enum_map.base_members.map { |member| [member[:key], not_collected_value] }.to_h,
            },
          )
        end

        it 'should set fields as expected when value is empty' do
          result = transformer.new(OpenStruct.new(field => [])).to_params
          not_collected_value = enum_map.lookup(key: not_collected_key)[:value]

          expect(result).to include(
            {
              none_field => not_collected_value,
              **enum_map.base_members.map { |member| [member[:key], not_collected_value] }.to_h,
            },
          )
        end

        it 'should set fields as expected when value is null' do
          result = transformer.new(OpenStruct.new(field => nil)).to_params

          expect(result.keys).not_to include(
            none_field,
            *enum_map.base_members.pluck(:key),
          )
        end
      end
    end
  end

  describe 'client creation tests' do
    let!(:ds1) { create :hmis_data_source }
    let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
    let(:mutation_test_input) do
      {
        **test_input,
        name_data_quality: Types::HmisSchema::Enums::Hud::NameDataQuality.values.first[0],
        dob_data_quality: Types::HmisSchema::Enums::Hud::DOBDataQuality.values.first[0],
        ssn_data_quality: Types::HmisSchema::Enums::Hud::SSNDataQuality.values.first[0],
        ethnicity: Types::HmisSchema::Enums::Hud::Ethnicity.values.first[0],
        veteran_status: Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData.values.first[0],
        gender: [Types::HmisSchema::Enums::Gender.values.first[0]],
        race: [Types::HmisSchema::Enums::Race.values.first[0]],
      }
    end

    before(:each) do
      hmis_login(user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateClient($input: ClientInput!) {
          createClient(input: { input: $input }) {
            client {
              dateCreated
              dateDeleted
              dateUpdated
              dob
              dobDataQuality
              ethnicity
              firstName
              gender
              id
              lastName
              middleName
              nameDataQuality
              nameSuffix
              personalId
              preferredName
              pronouns
              race
              ssn
              ssnDataQuality
              veteranStatus
              enrollments {
                nodes {
                  id
                  project {
                    id
                    projectName
                  }
                  entryDate
                  exitDate
                }
              }
            }
            errors {
              attribute
              message
              fullMessage
              type
              options
              __typename
            }
          }
        }
      GRAPHQL
    end

    it 'should create a client successfully' do
      response, result = post_graphql(input: mutation_test_input) { mutation }

      expect(response.status).to eq 200
      client = result.dig('data', 'createClient', 'client')
      errors = result.dig('data', 'createClient', 'errors')
      expect(client['id']).to be_present
      expect(errors).to be_empty
    end

    it 'should save and resolve race and gender correctly when missing' do
      mutation_input = {
        **mutation_test_input,
        gender: ['GENDER_DATA_NOT_COLLECTED'],
        race: ['RACE_REFUSED'],
      }

      response, result = post_graphql(input: mutation_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        client = result.dig('data', 'createClient', 'client')
        errors = result.dig('data', 'createClient', 'errors')
        expect(errors).to be_empty
        expect(client['id']).to be_present
        expect(client['race']).to contain_exactly('RACE_REFUSED')
        expect(client['gender']).to contain_exactly('GENDER_DATA_NOT_COLLECTED')
      end
    end

    it 'should save and resolve race and gender correctly when multiple present' do
      genders = ['GENDER_QUESTIONING', 'GENDER_MALE']
      races = ['RACE_ASIAN', 'RACE_BLACK_AF_AMERICAN']
      mutation_input = {
        **mutation_test_input,
        gender: genders,
        race: races,
      }
      response, result = post_graphql(input: mutation_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        client = result.dig('data', 'createClient', 'client')
        errors = result.dig('data', 'createClient', 'errors')
        expect(errors).to be_empty
        expect(client['id']).to be_present
        expect(client['race']).to contain_exactly(*races)
        expect(client['gender']).to contain_exactly(*genders)
      end
    end

    it 'should throw errors if the client is invalid' do
      response, result = post_graphql(input: {}) { mutation }

      client = result.dig('data', 'createClient', 'client')
      errors = result.dig('data', 'createClient', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(client).to be_nil
        expect(errors).to be_present
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
