###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# keycloak:backfill_authentication_sources — the CLI entry point around
# Idp::Keycloak::AuthenticationSourceBackfill. The linking behavior is covered in
# the service spec; this pins only what the task adds: it links end to end keyed
# on the resolved connector_id, and exits 1 when Keycloak isn't configured.
RSpec.describe 'keycloak:backfill_authentication_sources', type: :task do
  let(:task_name) { 'keycloak:backfill_authentication_sources' }

  let(:keycloak_users) { [{ email: 'person@example.com', id: 'kc-1' }] }
  let!(:user) { create(:user, email: 'person@example.com', confirmed_at: Time.current, active: true) }

  # A real KeycloakService (so the task's is_a? check passes) with the network
  # boundary stubbed: each_user yields whatever keycloak_users holds.
  let(:service) do
    Idp::KeycloakService.new(
      config: { api_url: 'http://kc.test', realm: 'openpath', client_id: 'x', client_secret: 'y' },
    ).tap do |s|
      allow(s).to receive(:each_user) { |&block| keycloak_users.each { |u| block.call(u) } }
    end
  end

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'keycloak:backfill_authentication_sources' }
  end

  before do
    Rake::Task[task_name].reenable
    allow(Idp::ServiceFactory).to receive(:for_connector).and_return(service)
  end

  def run(*args)
    Rake::Task[task_name].invoke(*args)
  end

  it 'links users, keying the row on the resolved connector_id' do
    run

    sources = user.reload.user_authentication_sources
    expect(sources.count).to eq(1)
    expect(sources.first.connector_id).to eq('keycloak')
  end

  it 'exits 1 without writing when Keycloak is not configured' do
    # for_connector('keycloak') yields a NullService when no real Keycloak is
    # configured; the task exits 1 rather than backfill, like the sibling tasks.
    allow(Idp::ServiceFactory).to receive(:for_connector).and_return(Idp::NullService.new('keycloak'))

    expect { run }.to raise_error('Error: Keycloak service not configured')
    expect(user.reload.user_authentication_sources.count).to eq(0)
  end
end
