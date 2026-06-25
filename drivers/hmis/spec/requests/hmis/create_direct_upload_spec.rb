###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_own_client_files]) }

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateDirectUpload($input: CreateDirectUploadInput!) {
        createDirectUpload(input: $input) {
          signedBlobId
          filename
          url
          headers
        }
      }
    GRAPHQL
  end

  let(:upload_input) do
    {
      filename: 'test.txt',
      byte_size: 4,
      checksum: 'dGVzdA==',
      content_type: 'text/plain',
    }
  end

  before(:each) do
    hmis_login(user)
  end

  def perform_mutation
    post_graphql(input: { input: upload_input }) { mutation }
  end

  it 'creates a direct upload when the user can upload files' do
    response, result = perform_mutation

    aggregate_failures do
      expect(response.status).to eq(200), result.inspect
      data = result.dig('data', 'createDirectUpload')
      expect(data['signedBlobId']).to be_present
      expect(data['filename']).to eq('test.txt')
      expect(data['url']).to be_present
      expect(ActiveStorage::Blob.find_signed(data['signedBlobId'])).to be_present
    end
  end

  context 'when the user can edit clients but not upload files' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_edit_clients]) }

    it 'allows direct upload for client profile images' do
      response, result = perform_mutation

      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createDirectUpload', 'signedBlobId')).to be_present
    end
  end

  context 'when the user lacks upload and edit permissions' do
    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients]) }

    it 'denies direct upload' do
      expect do
        expect_access_denied(perform_mutation)
      end.not_to change(ActiveStorage::Blob, :count)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
