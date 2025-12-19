###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'UpdateClientImage', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation UpdateClientImage($input: UpdateClientImageInput!) {
        updateClientImage(input: $input) {
          client {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_edit_clients]) }
  let!(:client) { create :hmis_hud_client, data_source: ds1 }
  let!(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open('drivers/hmis/spec/fixtures/files/client_photo_00001.jpg'),
      filename: 'client_photo_00001.jpg',
      content_type: 'image/jpeg',
    )
  end

  before(:each) do
    hmis_login(user)
  end

  it 'updates client image successfully' do
    input = { client_id: client.id, image_blob_id: blob.signed_id }

    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200)
    expect(result.dig('data', 'updateClientImage', 'client', 'id')).to eq(client.id.to_s)
    expect(result.dig('data', 'updateClientImage', 'errors')).to be_empty

    client.reload
    expect(client.client_files.count).to eq(1)
  end

  describe 'permissions' do
    it 'fails if user lacks can_edit_clients permission' do
      remove_permissions(access_control, :can_edit_clients)
      input = { client_id: client.id, image_blob_id: blob.signed_id }

      expect_gql_error post_graphql(input: input) { mutation }, message: 'Access denied'
    end

    it 'fails if user lacks can_view_clients permission' do
      remove_permissions(access_control, :can_view_clients)
      input = { client_id: client.id, image_blob_id: blob.signed_id }

      expect_gql_error post_graphql(input: input) { mutation }, message: 'Record not found'
    end
  end

  describe 'error handling' do
    it 'fails if client is not found' do
      input = { client_id: '999999', image_blob_id: blob.signed_id }

      expect_gql_error post_graphql(input: input) { mutation }, message: 'Record not found'
    end

    it 'fails if blob is not found' do
      input = { client_id: client.id, image_blob_id: 'invalid_blob_id' }

      response, result = post_graphql(input: input) { mutation }
      expect(response.status).to eq(200)
      expect(result.dig('data', 'updateClientImage', 'errors')).not_to be_empty
      expect(result.dig('data', 'updateClientImage', 'errors', 0, 'fullMessage')).to match(/No uploaded file found/)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
