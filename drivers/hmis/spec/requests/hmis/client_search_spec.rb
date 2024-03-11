###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  let!(:ds2) { create :hmis_data_source, hmis: nil }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query ClientSearch($input: ClientSearchInput!, $sortOrder: ClientSortOption = LAST_NAME_A_TO_Z) {
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

  context 'User access tests' do
    let!(:client1) { create :hmis_hud_client, data_source: ds1 }
    let!(:client2) { create :hmis_hud_client, data_source: ds2 }
    let!(:client3) { create :hmis_hud_client, data_source: ds1 }

    it 'should only show clients from HMIS data source' do
      response, result = post_graphql(input: {}) { query }

      expect(response.status).to eq 200
      clients = result.dig('data', 'clientSearch', 'nodes')
      expect(clients).to include({ 'id' => client1.id.to_s })
      expect(clients).not_to include({ 'id' => client2.id.to_s })
      expect(clients).to include({ 'id' => client3.id.to_s })
    end

    it 'should only show clients with enrollments at projects the user has view access for' do
      create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: client1, user: u1)
      create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: client3, user: u1)

      expect(client1.enrollments).to contain_exactly(satisfy { |e| !e.in_progress? })
      expect(client3.enrollments).to contain_exactly(satisfy { |e| !e.in_progress? })

      # Shouldn't see client3 since it has enrollments elsewhere
      _response, result = post_graphql(input: {}) { query }
      expect(result.dig('data', 'clientSearch', 'nodes')).to contain_exactly(include('id' => client1.id.to_s))

      create(:hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: client3, user: u1)
      client3.reload

      expect(client3.enrollments).to contain_exactly(satisfy { |e| !e.in_progress? }, satisfy(&:in_progress?))

      # Now we should see client3 since it has a WIP enrollment at our project
      _response, result = post_graphql(input: {}) { query }
      expect(result.dig('data', 'clientSearch', 'nodes')).to contain_exactly(include('id' => client1.id.to_s), include('id' => client3.id.to_s))
    end

    it 'should exclude clients enrolled at a project without user view permission' do
      # Grant user access to p2, but without the ability to view clients
      create_access_control(hmis_user, p2, without_permission: :can_view_clients)
      # Enroll client3 in p2
      create(:hmis_hud_enrollment, data_source: ds1, project: p2, client: client3, user: u1)

      response, result = post_graphql(input: {}) { query }
      expect(response.status).to eq 200
      clients = result.dig('data', 'clientSearch', 'nodes')
      expect(clients).to include({ 'id' => client1.id.to_s })
      expect(clients).not_to include({ 'id' => client2.id.to_s })
      expect(clients).not_to include({ 'id' => client3.id.to_s })
    end

    it 'should return no clients if user does not have permission to view clients' do
      remove_permissions(access_control, :can_view_clients)
      response, result = post_graphql(input: {}) { query }
      expect(response.status).to eq 200
      clients = result.dig('data', 'clientSearch', 'nodes')
      expect(clients).to be_empty
    end
  end

  describe 'Search tests' do
    let!(:client) do
      create(
        :hmis_hud_client,
        data_source: ds1,
        first_name: 'William',
        last_name: 'Smith',
        personal_id: 'db422f5fff0b8f1c9a4b81f01b00fdb4',
        ssn: '123456789',
        dob: '1999-12-01',
      )
    end

    # Create a Warehouse Destination Client with a fixed ID so we can search for it
    let!(:wh_client) do
      create(:hmis_hud_base_client, id: 5555)
      create(:hmis_warehouse_client, destination_id: 5555, data_source: client.data_source, source: client)
    end

    let!(:e1) { create(:hmis_hud_enrollment, client: client, data_source: ds1, project: p1) }
    let!(:e2_wip) { create(:hmis_hud_wip_enrollment, client: client, data_source: ds1, project: p1) }
    let!(:e3_other_hhm) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, household_id: e1.household_id) }
    let!(:e4) { create(:hmis_hud_enrollment, household_id: '999', client: client, data_source: ds1, project: p1) }

    let!(:scan_code) { create(:hmis_scan_card_code, client: client, value: 'P1234') }
    let!(:deactivated_scan_code) { create(:hmis_scan_card_code, client: client, value: 'P5678', deleted_at: Time.current - 2.days) }
    let!(:expired_scan_code) { create(:hmis_scan_card_code, client: client, value: 'P6666', expires_at: Date.current - 2.days) }
    let!(:other_scan_code) { create(:hmis_scan_card_code, value: 'P9999') }

    it 'should search' do
      [
        # TEXT SEARCHES
        *[
          ['text: first name', 'william', true],
          ['text: last name', 'smith', true],
          ['text: last, first', 'smith, william', true],
          ['text: first last', 'william smith', true],
          ['text: partial names', 'wi sm', true],
          ['text: wrong name and not match', 'x x', false],
          ['text: personal id', 'db422f5fff0b8f1c9a4b81f01b00fdb4', true],
          ['text: wrong personal id and not match', '00000000000000000000000000000000', false],
          ['text: ssn', '123-45-6789', true],
          ['text: wrong ssn and not match', '000-00-0000', false],
          ['text: dob', '12/01/1999', true],
          ['text: wrong dob and not match', '12/01/2000', false],
          ['text: warehouse id', '5555', true],
          ['text: scan card code', 'P1234', true],
          ['text: deactivated scan card code', 'P5678', false],
          ['text: expired scan card code', 'P6666', false],
          ['text: scan card code for another client', 'P9999', false],
          ['text: enrollment id', "enrollment:#{e1.id}", true],
          ['text: enrollment id with extra space', " enrollment:#{e1.id} ", true],
          ['text: enrollment id with extra space after colon', "enrollment: #{e1.id} ", true],
          ['text: WIP enrollment id', "enrollment:#{e2_wip.id}", true],
          ['text: enrollment id without correct prefix', e1.id, false],
          ['text: wrong enrollment id', 'enrollment:123', false],
          ['text: wrong enrollment id (other hhm\'s id)', "enrollment:#{e3_other_hhm.id}", false],
          ['text: non-numeric enrollment id', 'enrollment:123ABC', false],
          ['text: household id', "household:#{e1.household_id}", true],
          ['text: household id with extra dashes', "household:#{e1.household_id.insert(-9, '-')}", true],
          ['text: household id with extra space', " household:#{e1.household_id} ", true],
          ['text: household id with extra space after colon', "household: #{e1.household_id} ", true],
          ['text: numeric household id', 'household:999', true],
          ['text: WIP household id', "household:#{e2_wip.household_id}", true],
          ['text: household id without correct prefix', e1.household_id, false],
          ['text: wrong household id', 'householdid:notreal', false],
        ].map { |desc, text, match| [desc, { text_search: text.to_s }, match] },
        # OTHER FILTERS
        ['personal id', { personal_id: client.personal_id }, true],
        ['wrong personal id and not match', { personal_id: '00000000000000000000000000000000' }, false],
        ['warehouse id', { warehouse_id: '5555' }, true],
        ['wrong warehouse id', { warehouse_id: '5556' }, false],
        ['first name', { first_name: 'William' }, true],
        # TODO: Test nickname match
        # TODO: Test metaphone match
        ['wrong first name and not match', { first_name: 'Dave' }, false],
        ['last name', { last_name: 'Smith' }, true],
        # TODO: Test nickname match
        # TODO: Test metaphone match
        ['wrong last name and not match', { last_name: 'Jones' }, false],
        ['last 4 of ssn', { ssn_serial: '6789' }, true],
        ['wrong last 4 of ssn and not match', { ssn_serial: '0000' }, false],
        ['dob d/m/yyyy', { dob: '1/12/1999' }, true],
        ['dob yyyy-mm-dd', { dob: '1999-12-01' }, true],
        ['wrong dob and not match', { dob: '2000-12-01' }, false],
        # TODO: Projects filter
        # TODO: Organizations filter
      ].each do |desc, input, match|
        response, result = post_graphql(input: input) { query }
        aggregate_failures "checking #{desc}" do
          expect(response.status).to eq(200), "Failed: '#{desc}' #{result.inspect}"
          clients = result.dig('data', 'clientSearch', 'nodes')
          matcher = include({ 'id' => client.id.to_s })
          if match
            expect(clients).to matcher, "Failed: '#{desc}'"
          else
            expect(clients).not_to matcher, "Failed: '#{desc}'"
          end
        end
      end
    end
  end

  describe 'custom client names search tests' do
    let!(:client) do
      create(
        :hmis_hud_client,
        data_source: ds1,
        FirstName: 'db422f5fff0b8f1c9a4b81f01b00fdb4',
        LastName: 'db422f5fff0b8f1c9a4b81f01b00fdb4',
        PersonalID: 'db422f5fff0b8f1c9a4b81f01b00fdb4',
        SSN: '123456789',
        DOB: '1999-12-01',
      )
    end

    before(:each) do
      client.names.create!(
        first: 'William',
        last: 'Smith',
        user_id: client.user_id,
        data_source_id: client.data_source_id,
      )
    end

    [
      *[
        ['text: first name', 'william', true],
        ['text: last name', 'smith', true],
        ['text: last, first', 'smith, william', true],
        ['text: first last', 'william smith', true],
        ['text: partial names', 'wi sm', true],
      ].map { |desc, text, match| [desc, { text_search: text }, match] },
      ['first name', { first_name: 'William' }, true],
      ['last name', { last_name: 'Smith' }, true],
    ].each do |desc, input, match|
      it "should search custom client names by #{desc}" do
        response, result = post_graphql(input: input) { query }

        sleep(0.01) # sleep for some funky test failures(?)
        aggregate_failures 'checking response' do
          expect(response.status).to eq(200), result.inspect
          clients = result.dig('data', 'clientSearch', 'nodes')
          matcher = include({ 'id' => client.id.to_s })
          match ? expect(clients).to(matcher) : expect(clients).not_to(matcher)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
