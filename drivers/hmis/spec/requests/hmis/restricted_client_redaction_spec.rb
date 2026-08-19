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

  let!(:client) { create(:hmis_hud_client, data_source: ds1, with_enrollment_at: p1, dob: 18.years.ago.to_date, ssn: '123456789') }
  # User has every permission except the ability to view restricted clients
  let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_view_restricted_clients) }

  let!(:phone) { create(:hmis_hud_custom_client_contact_point, client: client, data_source: ds1, system: 'phone', value: '5555555555') }
  let!(:email) { create(:hmis_hud_custom_client_contact_point, client: client, data_source: ds1, system: 'email', value: 'client@e.mail') }
  let!(:address) { create(:hmis_hud_custom_client_address, client: client, data_source: ds1) }
  let!(:photo_blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open('drivers/hmis/spec/fixtures/files/client_photo_00001.jpg'),
      filename: 'client_photo_00001.jpg',
      content_type: 'image/jpeg',
    )
  end

  before(:each) do
    hmis_login(user)
    client.build_client_headshot_file(photo_blob.signed_id, u1)
    client.save!
  end

  let(:query) do
    <<~GRAPHQL
      query Client($id: ID!) {
        client(id: $id) {
          id
          restricted
          firstName
          middleName
          lastName
          dob
          ssn
          names {
            first
            last
          }
          image {
            id
          }
          phoneNumbers {
            value
          }
          emailAddresses {
            value
          }
          addresses {
            line1
          }
          access {
            canViewClientName
            canViewDob
            canViewPartialSsn
            canViewFullSsn
            canViewClientPhoto
            canEditClient
          }
        }
      }
    GRAPHQL
  end

  def resolve_client
    response, result = post_graphql(id: client.id.to_s) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client')
  end

  context 'when the client is not restricted' do
    it 'resolves PII, photo, and contact info' do
      expect(resolve_client).to include(
        'restricted' => false,
        'firstName' => client.first_name,
        'lastName' => client.last_name,
        'dob' => client.dob.strftime('%Y-%m-%d'),
        'ssn' => client.ssn,
        'image' => a_hash_including('id' => be_present),
        'phoneNumbers' => [{ 'value' => phone.value }],
        'emailAddresses' => [{ 'value' => email.value }],
        'addresses' => [{ 'line1' => address.line1 }],
        'access' => a_hash_including(
          'canViewClientName' => true,
          'canViewDob' => true,
          'canViewFullSsn' => true,
          'canViewClientPhoto' => true,
        ),
      )
    end
  end

  context 'when the client is restricted' do
    before(:each) { client.mark_as_restricted!(user: hmis_user) }

    it 'still resolves the client, with PII redacted and the corresponding access fields false' do
      expect(resolve_client).to include(
        'restricted' => true,
        'firstName' => client.masked_name,
        'middleName' => nil,
        'lastName' => nil,
        'dob' => nil,
        'ssn' => nil,
        'names' => [{ 'first' => client.masked_name, 'last' => nil }],
        'image' => nil,
        'phoneNumbers' => [],
        'emailAddresses' => [],
        'addresses' => [],
        'access' => a_hash_including(
          'canViewClientName' => false,
          'canViewDob' => false,
          'canViewPartialSsn' => false,
          'canViewFullSsn' => false,
          'canViewClientPhoto' => false,
          # unrelated permissions are not restricted
          'canEditClient' => true,
        ),
      )
    end

    it 'resolves PII for users who can view restricted clients' do
      add_permissions(access_control, :can_view_restricted_clients)

      expect(resolve_client).to include(
        'restricted' => true,
        'firstName' => client.first_name,
        'lastName' => client.last_name,
        'dob' => client.dob.strftime('%Y-%m-%d'),
        'ssn' => client.ssn,
        'image' => a_hash_including('id' => be_present),
        'phoneNumbers' => [{ 'value' => phone.value }],
        'access' => a_hash_including('canViewClientName' => true, 'canViewDob' => true, 'canViewClientPhoto' => true),
      )
    end
  end
end
