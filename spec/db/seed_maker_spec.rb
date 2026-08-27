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

  # The IdP config is materialized from ENV once, on deploy, through run_all. The full seeding
  # behavior (idempotency, no-clobber, soft-delete handling) is tested against
  # Idp::ServiceConfig.bootstrap_from_env; this proves the deploy path actually reaches it and
  # creates the row, so dropping the step from run_all can't pass unnoticed.
  describe '#run_all' do
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

    # Stub only the KEYCLOAK_* keys we read; everything else passes through.
    def stub_env(values)
      allow(ENV).to receive(:[]).and_call_original
      keycloak_env.each_key do |key|
        allow(ENV).to receive(:[]).with(key).and_return(values[key])
      end
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('KEYCLOAK_CONNECTOR_ID', 'keycloak').
        and_return(values.fetch('KEYCLOAK_CONNECTOR_ID', 'keycloak'))
    end

    before do
      allow(AuthMethod).to receive(:jwt?).and_return(true)
      stub_env(keycloak_env)

      # Neutralize the unrelated deploy steps: a full run_all loads HMIS data, shapefiles,
      # translations, etc. — too heavy and brittle to run here. The IdP seed itself runs for real.
      [
        :ensure_db_triggers_and_functions, :maintain_data_sources, :maintain_db_monitor_defaults, :maintain_cp_seed, :setup_hmis_admin_access, :load_hmis_data, :install_shapes, :maintain_lookups, :maintain_system_groups, :populate_internal_system_choices
      ].each { |step| allow(seed_maker).to receive(step) }

      allow(GrdaWarehouse::WarehouseReports::ReportDefinition).to receive(:maintain_report_definitions)
      allow(GrdaWarehouse::Help).to receive(:setup_default_links)
      allow(GrdaWarehouse::SystemColor).to receive(:ensure_colors)
      allow(Translation).to receive(:maintain_keys)
      allow(GrdaWarehouse::Cohorts::CohortColumn).to receive(:maintain!)
    end

    it 'materializes the IdP service config from ENV' do
      expect { seed_maker.run_all }.to change(Idp::ServiceConfig, :count).by(1)

      expect(Idp::ServiceConfig.find_by(connector_id: 'keycloak')).to have_attributes(
        provider: 'keycloak',
        name: 'Keycloak (seeded from ENV)',
      )
    end
  end

  describe '#maintain_db_monitor_defaults' do
    it 'creates the alert threshold with a default that reads as 10' do
      expect { seed_maker.maintain_db_monitor_defaults }.
        to change { AppConfigProperty.where(key: 'wh_db_space_monitor/alert_threshold_pct').count }.by(1)

      expect(GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration.new.alert_threshold_pct).to eq(10)
    end

    it 'does not override an existing value' do
      AppConfigProperty.create!(key: 'wh_db_space_monitor/alert_threshold_pct', value: 20)

      expect { seed_maker.maintain_db_monitor_defaults }.
        not_to(change { AppConfigProperty.find_by(key: 'wh_db_space_monitor/alert_threshold_pct').value })

      expect(GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration.new.alert_threshold_pct).to eq(20)
    end
  end
end
