###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'DeleteClientImage', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteClientImage($input: DeleteClientImageInput!) {
        deleteClientImage(input: $input) {
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
    client.build_client_headshot_file(blob.signed_id, u1)
    client.save!
  end

  it 'deletes client image successfully' do
    expect(client.client_files.count).to eq(1)

    input = { client_id: client.id }

    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200)
    expect(result.dig('data', 'deleteClientImage', 'client', 'id')).to eq(client.id.to_s)
    expect(result.dig('data', 'deleteClientImage', 'errors')).to be_empty

    client.reload
    expect(client.client_files.count).to eq(0)
  end

  describe 'permissions' do
    it 'fails if user lacks can_edit_clients permission' do
      remove_permissions(access_control, :can_edit_clients)
      input = { client_id: client.id }

      expect_access_denied post_graphql(input: input) { mutation }
    end

    it 'fails if user lacks can_view_clients permission' do
      remove_permissions(access_control, :can_view_clients)
      input = { client_id: client.id }

      expect_access_denied post_graphql(input: input) { mutation }
    end
  end

  describe 'error handling' do
    it 'fails if client is not found' do
      input = { client_id: '999999' }

      expect_access_denied post_graphql(input: input) { mutation }
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
