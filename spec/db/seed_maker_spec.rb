###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('db/seed_maker')

RSpec.describe SeedMaker do
  subject(:seed_maker) { described_class.new }

  let(:keycloak_env) do
    {
      'KEYCLOAK_API_URL' => 'http://seed.keycloak:8080',
      'KEYCLOAK_REALM' => 'seed-realm',
      'KEYCLOAK_SERVICE_CLIENT_ID' => 'seed-client',
      'KEYCLOAK_SERVICE_CLIENT_SECRET' => 'seed-secret',
      'KEYCLOAK_PUBLIC_URL' => 'https://seed.public.test',
      'KEYCLOAK_ACCOUNT_CLIENT_ID' => 'seed-account',
    }
  end

  KEYCLOAK_SEED_KEYS = [
    'KEYCLOAK_API_URL',
    'KEYCLOAK_REALM',
    'KEYCLOAK_SERVICE_CLIENT_ID',
    'KEYCLOAK_SERVICE_CLIENT_SECRET',
    'KEYCLOAK_PUBLIC_URL',
    'KEYCLOAK_ACCOUNT_CLIENT_ID',
  ].freeze

  # Stub only the KEYCLOAK_* keys we read; everything else passes through.
  def stub_env(values)
    allow(ENV).to receive(:[]).and_call_original
    KEYCLOAK_SEED_KEYS.each do |key|
      allow(ENV).to receive(:[]).with(key).and_return(values[key])
    end
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('KEYCLOAK_CONNECTOR_ID', 'keycloak').
      and_return(values.fetch('KEYCLOAK_CONNECTOR_ID', 'keycloak'))
  end

  describe '#seed_idp_service_config' do
    context 'in JWT mode with core KEYCLOAK_* env present' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env(keycloak_env)
      end

      it 'creates one active Idp::ServiceConfig from ENV' do
        expect { seed_maker.seed_idp_service_config }.to change(Idp::ServiceConfig, :count).by(1)

        config = Idp::ServiceConfig.find_by(connector_id: 'keycloak')
        expect(config).to have_attributes(
          provider: 'keycloak',
          connector_id: 'keycloak',
          name: 'Keycloak (seeded from ENV)',
          api_url: 'http://seed.keycloak:8080',
          keycloak_realm: 'seed-realm',
          client_id: 'seed-client',
          browser_url: 'https://seed.public.test',
          account_client_id: 'seed-account',
          manage_users: true,
          active: true,
        )
        expect(config.service_token).to eq('seed-secret')
      end

      it 'uses KEYCLOAK_CONNECTOR_ID as the connector_id when set' do
        stub_env(keycloak_env.merge('KEYCLOAK_CONNECTOR_ID' => 'realm-a'))

        seed_maker.seed_idp_service_config

        expect(Idp::ServiceConfig.find_by(connector_id: 'realm-a')).to be_present
      end
    end

    context 'when not in JWT mode' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(false)
        stub_env(keycloak_env)
      end

      it 'is a no-op' do
        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
      end
    end

    context 'when core KEYCLOAK_* env is absent (external IdP)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env({}) # every KEYCLOAK_* key nil
      end

      it 'is a silent no-op and does not raise' do
        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
      end
    end

    context 'with a partial KEYCLOAK_* env (a core build key absent)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
      end

      it 'is a silent no-op when KEYCLOAK_REALM is absent' do
        stub_env(keycloak_env.merge('KEYCLOAK_REALM' => nil))

        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
      end

      it 'is a silent no-op when KEYCLOAK_SERVICE_CLIENT_ID is absent' do
        stub_env(keycloak_env.merge('KEYCLOAK_SERVICE_CLIENT_ID' => nil))

        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
      end
    end

    context 're-seeding (runs on every deploy)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env(keycloak_env)
      end

      it 'does not create a second row or clobber a UI credential edit' do
        seed_maker.seed_idp_service_config
        existing = Idp::ServiceConfig.find_by(connector_id: 'keycloak')
        existing.update!(api_url: 'http://ui-edited.keycloak:8080')

        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
        expect(existing.reload.api_url).to eq('http://ui-edited.keycloak:8080')
      end

      it 'does not resurrect a soft-deleted row' do
        seed_maker.seed_idp_service_config
        Idp::ServiceConfig.find_by(connector_id: 'keycloak').destroy

        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
        expect(Idp::ServiceConfig.find_by(connector_id: 'keycloak')).to be_nil
        expect(Idp::ServiceConfig.with_deleted.find_by(connector_id: 'keycloak')).to be_present
      end

      it 'does not reactivate a deactivated (active: false) row' do
        seed_maker.seed_idp_service_config
        Idp::ServiceConfig.find_by(connector_id: 'keycloak').update!(active: false)

        expect { seed_maker.seed_idp_service_config }.not_to change(Idp::ServiceConfig, :count)
        expect(Idp::ServiceConfig.find_by(connector_id: 'keycloak').active).to be(false)
      end
    end
  end
end
