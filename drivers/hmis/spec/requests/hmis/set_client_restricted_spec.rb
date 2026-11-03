# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: create(:hmis_hud_organization, data_source: ds1) }
  let!(:client) { create(:hmis_hud_client, data_source: ds1, with_enrollment_at: p1) }
  let!(:access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: [:can_view_clients, :can_view_restricted_clients, :can_mark_clients_as_restricted],
    )
  end

  before(:each) { hmis_login(user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation SetClientRestricted($clientId: ID!, $restricted: Boolean!) {
        setClientRestricted(clientId: $clientId, restricted: $restricted) {
          client {
            id
            restricted
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'marks a client as restricted' do
    response, result = post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'setClientRestricted', 'client', 'restricted')).to eq(true)
    expect(client.reload.restricted?).to be true
  end

  it 'removes restriction' do
    client.mark_as_restricted!(user: hmis_user)
    response, result = post_graphql(clientId: client.id.to_s, restricted: false) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'setClientRestricted', 'client', 'restricted')).to eq(false)
    expect(client.reload.restricted?).to be false
  end

  it 'denies users without mark permission' do
    remove_permissions(access_control, :can_mark_clients_as_restricted)
    expect_access_denied post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
  end

  it 'denies users without view permission' do
    remove_permissions(access_control, :can_view_restricted_clients)
    expect_access_denied post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
  end

  it 'creates an audit trail entry when marking as restricted' do
    expect do
      response, = post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
      expect(response.status).to eq(200)
    end.to change {
      GrdaWarehouse.paper_trail_versions.where(item_type: 'Hmis::RestrictedRecord').count
    }.by(1)
  end

  it 'creates an audit trail entry when removing restriction' do
    client.mark_as_restricted!(user: hmis_user)
    expect do
      response, = post_graphql(clientId: client.id.to_s, restricted: false) { mutation }
      expect(response.status).to eq(200)
    end.to change {
      GrdaWarehouse.paper_trail_versions.where(item_type: 'Hmis::RestrictedRecord').count
    }.by(1)
  end

  # The two examples above restrict a client that has never been restricted, which is the only
  # case the old RestrictedRecord.mark! handled with a create. Restricting a second time revived
  # the soft-deleted row through Paranoia, which writes with update_columns and skips PaperTrail.
  # The same user restricts in both directions here, so the created_by re-stamp that followed the
  # revive had nothing to save either, and the second restriction reached the audit trail as
  # nothing at all.
  it 'creates an audit trail entry when restricting a client that was restricted once before' do
    client.mark_as_restricted!(user: hmis_user)
    client.reload.remove_restriction!

    expect do
      response, = post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
      expect(response.status).to eq(200)
    end.to change {
      GrdaWarehouse.paper_trail_versions.where(item_type: 'Hmis::RestrictedRecord', event: 'create').count
    }.by(1)
  end

  it 'attributes both directions to the acting user' do
    post_graphql(clientId: client.id.to_s, restricted: true) { mutation }
    post_graphql(clientId: client.id.to_s, restricted: false) { mutation }

    versions = GrdaWarehouse.paper_trail_versions.
      where(item_type: 'Hmis::RestrictedRecord', client_id: client.id)

    expect(versions.pluck(:event, :whodunnit)).to contain_exactly(
      ['create', hmis_user.id.to_s],
      ['destroy', hmis_user.id.to_s],
    )
  end
end
