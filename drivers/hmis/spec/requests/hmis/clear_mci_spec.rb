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

  let(:stub_mci) { double }

  before(:each) do
    hmis_login(user)

    # Stub MCI clearance method
    allow(HmisExternalApis::AcHmis::Mci).to receive(:new).and_return(stub_mci)
  end

  let!(:mci_cred) do
    create(:ac_hmis_mci_credential)
  end

  let(:stub_clearance_results) do
    [
      build(:mci_clearance_result, mci_id: '10', score: 80, client: build(:hmis_hud_client, first_name: 'rita', woman: 1), existing_client_id: 100),
      build(:mci_clearance_result, mci_id: '50', score: 90, client: build(:hmis_hud_client, first_name: 'reet', woman: 1, man: 1)),
      build(:mci_clearance_result, mci_id: '80', score: 50),
    ]
  end

  let(:input) do
    {
      first_name: 'first',
      middle_name: 'middle',
      last_name: 'last',
      ssn: '111223333',
      dob: 50.years.ago.strftime('%Y-%m-%d'),
      gender: [
        Types::HmisSchema::Enums::Gender.key_for(0), # woman
        Types::HmisSchema::Enums::Gender.key_for(1), # man
      ],
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation ClearMci($input: ClearMciInput!) {
        clearMci(input: $input) {
          matches {
            #{scalar_fields(Types::AcHmis::MciClearanceMatch)}
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def mutate(**kwargs)
    response, result = post_graphql(**kwargs) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      matches = result.dig('data', 'clearMci', 'matches')
      errors = result.dig('data', 'clearMci', 'errors')
      yield matches, errors
    end
  end

  it 'should transform MciClearanceInput into Client with correct values' do
    attrs = { **input, gender: [0, 1] }
    client = Types::AcHmis::MciClearanceInput.to_client(attrs, hmis_user)

    expect(client.persisted?).to eq(false)
    expect(client.first_name).to eq(input[:first_name])
    expect(client.middle_name).to eq(input[:middle_name])
    expect(client.last_name).to eq(input[:last_name])
    expect(client.name_data_quality).to eq(1)
    expect(client.ssn).to eq(input[:ssn])
    expect(client.ssn_data_quality).to eq(1)
    expect(client.dob).to eq(Date.parse(input[:dob]))
    expect(client.dob_data_quality).to eq(1)
    expect(client.gender_multi).to eq([0, 1])
  end

  it 'should transform MciClearanceInput into Client with minimal values' do
    attrs = input.except(:middle_name, :ssn, :gender)
    client = Types::AcHmis::MciClearanceInput.to_client(attrs, hmis_user)

    expect(client.persisted?).to eq(false)
    expect(client.first_name).to eq(input[:first_name])
    expect(client.middle_name).to be nil
    expect(client.last_name).to eq(input[:last_name])
    expect(client.ssn).to be nil
    expect(client.ssn_data_quality).to eq(99)
    expect(client.dob).to eq(Date.parse(input[:dob]))
    expect(client.gender_multi).to eq([99])
  end

  it 'should resolve MCI matches above a certain threshold' do
    allow(stub_mci).to receive(:clearance).and_return(stub_clearance_results)

    num_clients = Hmis::Hud::Client.all.size

    expected_matches = [
      a_hash_including('score' => 90, 'mciId' => '50', 'firstName' => 'reet', 'existingClientId' => nil, 'gender' => ['WOMAN', 'MAN']),
      a_hash_including('score' => 80, 'mciId' => '10', 'firstName' => 'rita', 'existingClientId' => '100', 'gender' => ['WOMAN']),
    ]

    mutate(input: { input: input }) do |matches, errors|
      expect(errors).to be_empty
      expect(matches).to match(expected_matches)
      expect(Hmis::Hud::Client.all.size).to eq(num_clients) # nothing persisted
    end
  end

  it 'should succeed if no MCI matches' do
    allow(stub_mci).to receive(:clearance).and_return([])
    mutate(input: { input: input }) do |matches, errors|
      expect(matches).to be_empty
      expect(errors).to be_empty
    end
  end

  it 'should drop other matches if auto-clearance threshold is met' do
    stub_clearance_results[0].score = 97
    stub_clearance_results[1].score = 98
    stub_clearance_results[2].score = 85
    allow(stub_mci).to receive(:clearance).and_return(stub_clearance_results)

    mutate(input: { input: input }) do |matches, errors|
      expect(errors).to be_empty
      expect(matches.length).to eq(1)
      expect(matches).to contain_exactly(a_hash_including('score' => 98))
    end
  end

  it 'should prefer existing clients for auto-clearance if match score is the same' do
    stub_clearance_results[0].score = 97
    stub_clearance_results[0].existing_client_id = nil
    stub_clearance_results[1].score = 97
    stub_clearance_results[1].existing_client_id = '123'

    allow(stub_mci).to receive(:clearance).and_return(stub_clearance_results)

    mutate(input: { input: input }) do |matches, errors|
      expect(errors).to be_empty
      expect(matches.length).to eq(1)
      expect(matches).to contain_exactly(a_hash_including('existingClientId' => '123'))
    end
  end

  it 'should catch and resolve errors' do
    allow(stub_mci).to receive(:clearance).and_raise(StandardError, 'Test error')
    expect_gql_error(post_graphql(input: { input: input }) { mutation })
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
