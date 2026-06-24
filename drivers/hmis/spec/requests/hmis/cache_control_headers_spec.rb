###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'HMIS Cache-Control headers', type: :request do
  include_context 'hmis base setup'

  let!(:data_source) { create(:hmis_data_source, hmis: 'www.example.com') }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:query) do
    '{ __typename }'
  end

  context 'when authenticated' do
    before(:each) do
      hmis_login(user)
      post '/hmis/hmis-gql', params: { query: query }.to_json, headers: { 'Content-Type' => 'application/json' }
    end

    it 'sets no-store Cache-Control' do
      expect(response.headers['Cache-Control']).to include('no-store')
    end

    it 'sets Pragma no-cache' do
      expect(response.headers['Pragma']).to eq('no-cache')
    end

    it 'sets a past Expires date' do
      expect(response.headers['Expires']).to be_present
    end
  end

  context 'when not authenticated' do
    before do
      post '/hmis/hmis-gql', params: { query: query }.to_json, headers: { 'Content-Type' => 'application/json' }
    end

    it 'does not set no-store Cache-Control' do
      cache_control = response.headers['Cache-Control'] || ''
      expect(cache_control).not_to include('no-store')
    end
  end
end
