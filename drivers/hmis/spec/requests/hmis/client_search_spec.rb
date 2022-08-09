require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  let(:user) { create :user }
  let!(:ds1) { create :hmis_data_source }
  let!(:ds2) { create :hmis_data_source, hmis: nil, id: 2 }

  before(:all) do
    GrdaWarehouse::Utility.clear!
  end

  before(:each) do
    user.add_viewable(ds1)
    post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
  end

  let(:query) do
    <<~GRAPHQL
      query ClientSearch($input: ClientSearchInput!, $sortOrder: ClientSortOption = LAST_NAME_ASC) {
        clientSearch(
          limit: 100,
          offset: 0,
          sortOrder: $sortOrder,
          input: $input
        ) {
          nodes {
            id
          }
        }
      }
    GRAPHQL
  end

  describe 'User access tests' do
    it 'should only show clients from HMIS data source' do
      client1 = create :hmis_hud_client, data_source: ds1
      client2 = create :hmis_hud_client, data_source: ds2

      response, result = post_graphql(input: {}) { query }

      expect(response.status).to eq 200
      clients = result.dig('data', 'clientSearch', 'nodes')
      expect(clients).to include({ 'id' => client1.id.to_s })
      expect(clients).not_to include({ 'id' => client2.id.to_s })
    end
  end

  describe 'Search tests' do
    before(:each) do
      create(
        :hmis_hud_client,
        data_source: ds1,
        FirstName: 'William',
        LastName: 'Smith',
        preferred_name: 'Bill',
        PersonalID: 'db422f5fff0b8f1c9a4b81f01b00fdb4',
        # warehouse_id: '85e55698e335bdbcc3ead1b39828ee92',
        SSN: '123456789',
        DOB: '1999-12-01',
      )
    end

    let(:client) { Hmis::Hud::Client.first }

    [
      # TEXT SEARCHES
      *[
        ['text: first name', 'william', true],
        ['text: last name', 'smith', true],
        ['text: last, first', 'smith, william', true],
        ['text: first last', 'william smith', true],
        ['text: partial names', 'w s', true],
        ['text: wrong name and not match', 'x x', false],
        ['text: personal id', 'db422f5fff0b8f1c9a4b81f01b00fdb4', true],
        ['text: wrong personal id and not match', '00000000000000000000000000000000', false],
        ['text: ssn', '123-45-6789', true],
        ['text: wrong ssn and not match', '000-00-0000', false],
        ['text: dob', '12/01/1999', true],
        ['text: wrong dob and not match', '12/01/2000', false],
        # TODO: Test nickname match
        # TODO: Test metaphone match
      ].map { |desc, text, match| [desc, { text_search: text }, match] },
      # OTHER FILTERS
      ['personal id', { personal_id: 'db422f5fff0b8f1c9a4b81f01b00fdb4' }, true],
      ['wrong personal id and not match', { personal_id: '00000000000000000000000000000000' }, false],
      # ['warehouse id', { warehouse_id: 'db422f5fff0b8f1c9a4b81f01b00fdb4' }, true],
      # ['wrong warehouse id and not match', { warehouse_id: '00000000000000000000000000000000' }, false],
      ['first name', { first_name: 'William' }, true],
      # TODO: Test nickname match
      # TODO: Test metaphone match
      ['wrong first name and not match', { first_name: 'Dave' }, false],
      ['last name', { last_name: 'Smith' }, true],
      # TODO: Test nickname match
      # TODO: Test metaphone match
      ['wrong last name and not match', { last_name: 'Jones' }, false],
      ['preferred name', { preferred_name: 'Bill' }, true],
      ['wrong preferred name and not match', { preferred_name: 'Rich' }, false],
      ['last 4 of ssn', { ssn_serial: '6789' }, true],
      ['wrong last 4 of ssn and not match', { ssn_serial: '0000' }, false],
      ['dob d/m/yyyy', { dob: '1/12/1999' }, true],
      ['dob yyyy-mm-dd', { dob: '1999-12-01' }, true],
      ['wrong dob and not match', { dob: '2000-12-01' }, false],
      # TODO: Projects filter
      # TODO: Organizations filter
    ].each do |desc, input, match|
      it "should search by #{desc}" do
        response, result = post_graphql(input: input) { query }
        expect(response.status).to eq 200
        clients = result.dig('data', 'clientSearch', 'nodes')
        matcher = include({ 'id' => client.id.to_s })
        match ? expect(clients).to(matcher) : expect(clients).not_to(matcher)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
