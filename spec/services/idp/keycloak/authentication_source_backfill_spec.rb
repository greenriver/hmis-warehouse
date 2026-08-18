###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The service both keycloak:backfill_authentication_sources and the nightly
# Importing::RunDailyImportsJob drive. This spec owns the linking behavior —
# tallying, idempotency, already-linked, missing, inactive/unconfirmed
# accounts, duplicate, and the first-login race. Service resolution and
# connector_id sourcing now live in the callers (they pass both in); the rake
# and job specs cover that wiring.
RSpec.describe Idp::Keycloak::AuthenticationSourceBackfill do
  # A real KeycloakService with the network boundary stubbed: each_user yields
  # whatever keycloak_users holds.
  let(:keycloak_users) { [] }
  let(:service) do
    Idp::KeycloakService.new(
      config: { api_url: 'http://kc.test', realm: 'openpath', client_id: 'x', client_secret: 'y' },
    ).tap do |s|
      allow(s).to receive(:each_user) { |&block| keycloak_users.each { |u| block.call(u) } }
    end
  end

  # connector_id (the JWT routing key rows are keyed on) is passed in by the
  # caller. Deliberately NOT equal to the provider ('keycloak') so an assertion on
  # the written connector_id fails if the code ever writes the provider instead.
  let(:connector_id) { 'keycloak-prod' }

  describe '#call' do
    subject(:backfill) { described_class.new(service: service, connector_id: connector_id) }

    context 'with users to link, already linked, and missing from Keycloak' do
      let(:keycloak_users) do
        [
          { email: 'linked@example.com', id: 'kc-1' },
          { email: 'already@example.com', id: 'kc-3' },
          # ghost@example.com is in scope locally but absent from Keycloak.
        ]
      end
      let!(:to_link) { create(:user, email: 'linked@example.com', confirmed_at: Time.current, active: true) }
      let!(:already) { create(:user, email: 'already@example.com', confirmed_at: Time.current, active: true) }
      let!(:ghost) { create(:user, email: 'ghost@example.com', confirmed_at: Time.current, active: true) }

      before do
        already.user_authentication_sources.create!(connector_id: connector_id, connector_user_id: 'kc-3')
      end

      it 'tallies linked, already-linked, and missing users' do
        result = backfill.call

        expect(result).to have_attributes(total: 3, linked: 1, already: 1, missing: 1)
        # Newly linked with the Keycloak id.
        expect(to_link.reload.user_authentication_sources.pluck(:connector_user_id)).to eq(['kc-1'])
        # Missing from KC: no source written under a guessed id.
        expect(ghost.reload.user_authentication_sources.count).to eq(0)
        # Already linked: untouched, no duplicate.
        expect(already.reload.user_authentication_sources.count).to eq(1)
      end
    end

    context 'linking a single imported user' do
      let(:keycloak_users) { [{ email: 'person@example.com', id: 'kc-1' }] }
      # Mixed-case warehouse email must still match the downcased Keycloak email.
      let!(:user) { create(:user, email: 'Person@Example.com', confirmed_at: Time.current, active: true) }

      it 'writes the resolved connector_id and leaves last_connector_id nil' do
        backfill.call

        sources = user.reload.user_authentication_sources
        expect(sources.count).to eq(1)
        expect(sources.first).to have_attributes(connector_id: connector_id, connector_user_id: 'kc-1')
        expect(user.last_connector_id).to be_nil
      end

      it 'is idempotent: a second call creates no additional rows' do
        backfill.call
        backfill.call

        expect(user.reload.user_authentication_sources.count).to eq(1)
      end
    end

    context 'a user who is inactive or unconfirmed locally' do
      let(:keycloak_users) { [{ email: 'inactive@example.com', id: 'kc-1' }] }
      # Linking does not depend on local account status: a deactivated or
      # unconfirmed user can still hold a real Keycloak account (e.g. from
      # before deactivation, or created outside the migration tooling), and
      # first-login provisioning links regardless of local status too, so the
      # backfill must not silently leave these out of scope.
      let!(:user) { create(:user, email: 'inactive@example.com', confirmed_at: nil, active: false) }

      it 'is linked despite being inactive and unconfirmed' do
        result = backfill.call

        expect(result).to have_attributes(total: 1, linked: 1)
        expect(user.reload.user_authentication_sources.pluck(:connector_user_id)).to eq(['kc-1'])
      end
    end

    context 'a user already linked to a different IdP' do
      let(:keycloak_users) { [{ email: 'multi@example.com', id: 'kc-1' }] }
      let!(:user) { create(:user, email: 'multi@example.com', confirmed_at: Time.current, active: true) }

      before do
        user.user_authentication_sources.create!(connector_id: 'okta-prod', connector_user_id: 'okta-1')
      end

      it 'links the Keycloak source alongside the existing one, without disturbing it' do
        result = backfill.call

        expect(result).to have_attributes(total: 1, linked: 1)
        sources = user.reload.user_authentication_sources
        expect(sources.count).to eq(2)
        expect(sources.find_by(connector_id: 'okta-prod')).to have_attributes(connector_user_id: 'okta-1')
        expect(sources.find_by(connector_id: connector_id)).to have_attributes(connector_user_id: 'kc-1')
      end
    end

    context 'a user with a live link for this connector under a different id' do
      # e.g. the Keycloak account was recreated with a new subject
      let(:keycloak_users) { [{ email: 'recreated@example.com', id: 'kc-new' }] }
      let!(:user) { create(:user, email: 'recreated@example.com', confirmed_at: Time.current, active: true) }

      before do
        user.user_authentication_sources.create!(connector_id: connector_id, connector_user_id: 'kc-old')
      end

      it 'does not crash and leaves the existing link in place' do
        result = nil
        expect { result = backfill.call }.not_to raise_error

        expect(result).to have_attributes(total: 1, linked: 0, already: 1)
        sources = user.reload.user_authentication_sources
        expect(sources.pluck(:connector_user_id)).to eq(['kc-old'])
      end
    end

    context 'the system user' do
      let(:keycloak_users) { [{ email: 'noreply@greenriver.com', id: 'kc-sys' }] }

      it 'is excluded from scope even if Keycloak has a matching account' do
        result = backfill.call

        expect(result.total).to eq(0)
        expect(User.system_user.reload.user_authentication_sources.count).to eq(0)
      end
    end

    context 'duplicate downcased emails in Keycloak' do
      let(:keycloak_users) do
        [
          { email: 'Dup@example.com', id: 'kc-1' },
          { email: 'dup@example.com', id: 'kc-2' },
        ]
      end

      it 'raises rather than guessing which account to link' do
        expect { backfill.call }.to raise_error(Idp::ServiceError, /Duplicate Keycloak users/)
      end
    end

    context 'a concurrent first-login race' do
      let(:keycloak_users) { [{ email: 'person@example.com', id: 'kc-1' }] }
      let!(:user) { create(:user, email: 'person@example.com', confirmed_at: Time.current, active: true) }

      it 'swallows RecordNotUnique from the lost insert and counts it as already-linked' do
        # The concurrent first-login has already committed the durable row for this
        # pair (created outside the backfill's own insert transaction, so it is not
        # rolled back when that insert fails below).
        competing = user.user_authentication_sources.create!(connector_id: connector_id, connector_user_id: 'kc-1')

        # Model the race window: both the backfill's own existence guard AND
        # ActiveRecord's uniqueness validator run their SELECT before the competing
        # row is visible, so force those checks to miss (both go through
        # Relation#exists?). The insert itself is NOT stubbed: the backfill's real
        # create! then reaches the real partial unique index, which is what
        # actually turns the lost race into RecordNotUnique. A dropped or
        # misconfigured index would insert a duplicate and fail this test.
        allow_any_instance_of(ActiveRecord::Relation).to receive(:exists?).and_return(false)

        result = nil
        expect { result = backfill.call }.not_to raise_error

        # linked: 0 proves the insert did not silently succeed (a second row);
        # already: 1 proves the rescue counted the lost race.
        expect(result).to have_attributes(linked: 0, already: 1)
        # Exactly one live row survives, and it is the competing first-login's —
        # the real index, not a stub, prevented the duplicate.
        expect(user.reload.user_authentication_sources.pluck(:id)).to eq([competing.id])
      end
    end
  end

  describe 'the progress bar' do
    # ProgressBar divides by its total, so a fresh deployment (empty scope) must
    # not get a bar even when progress output is requested, or it divides by zero.
    it 'is not built on an empty scope even when progress is requested' do
      expect(ProgressBar).not_to receive(:new)

      described_class.new(service: service, connector_id: connector_id, progress: true)
    end
  end
end
