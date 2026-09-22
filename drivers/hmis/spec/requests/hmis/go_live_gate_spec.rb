###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'HMIS go-live gate', type: :request do
  include_context 'hmis base setup'

  let(:headers) { { 'HOST' => ds1.hmis } }
  let(:query) { '{ currentUser { id } }' }

  def post_graphql
    post '/hmis/hmis-gql', params: { query: query }.to_json, headers: graphql_post_headers(headers)
  end

  before { create_access_control(hmis_user, ds1, without_permission: [:can_administer_hmis]) }

  context 'while the HMIS is live' do
    it 'serves GraphQL and the bootstrap payload for a user in an HMIS user group' do
      hmis_login(user)

      post_graphql
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig('data', 'currentUser', 'id')).to eq(hmis_user.id.to_s)

      get hmis_user_path, headers: headers
      expect(JSON.parse(response.body)['id']).to eq(hmis_user.id.to_s)
      expect(JSON.parse(response.body)).not_to have_key('accountError')
    end
  end

  # Sessions are opened while live and the time is moved afterwards, so these examples exercise
  # the per-request check rather than the Devise login refusal (covered in sessions_controller_spec).
  context 'before the go-live time' do
    def go_not_live
      ds1.update!(hmis_go_live_at: 1.day.from_now)
    end

    it 'answers 403 no_hmis_access on GraphQL for a user in an HMIS user group' do
      hmis_login(user)
      go_not_live

      post_graphql

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq('error' => { 'type' => 'no_hmis_access' })
    end

    it 'answers the bootstrap payload with only accountError, no user fields' do
      hmis_login(user)
      go_not_live

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('impersonating' => false, 'accountError' => 'no_hmis_access')
    end

    it 'still serves a user who can administer HMIS' do
      add_permissions(hmis_user.access_controls.first, :can_administer_hmis)
      hmis_login(user)
      go_not_live

      post_graphql
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig('data', 'currentUser', 'id')).to eq(hmis_user.id.to_s)

      get hmis_user_path, headers: headers
      expect(JSON.parse(response.body)['id']).to eq(hmis_user.id.to_s)
    end

    it 'blocks a session that was open before the go-live time moved into the future' do
      hmis_login(user)
      post_graphql
      expect(response).to have_http_status(:ok)

      go_not_live
      post_graphql

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('no_hmis_access')
    end

    it 'does not touch warehouse sign-in for the blocked user', :devise_only do
      go_not_live
      sign_in user
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
