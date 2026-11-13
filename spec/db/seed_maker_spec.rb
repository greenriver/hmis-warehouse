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
    it 'creates the alert and block thresholds' do
      expect { seed_maker.maintain_db_monitor_defaults }.
        to change { AppConfigProperty.where("key LIKE 'wh_db_space_monitor/%'").count }.by(2)

      config = GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration.new
      expect(config.alert_threshold_pct).to eq(10)
      expect(config.block_threshold_pct).to eq(5)
    end

    it 'does not override an existing value' do
      AppConfigProperty.create!(key: 'wh_db_space_monitor/alert_threshold_pct', value: 20)

      expect { seed_maker.maintain_db_monitor_defaults }.
        not_to(change { AppConfigProperty.find_by(key: 'wh_db_space_monitor/alert_threshold_pct').value })

      expect(GrdaWarehouse::DbMonitor::FreeStorageSpaceConfiguration.new.alert_threshold_pct).to eq(20)
    end
  end

  describe '#seed_roles' do
    let(:default_role_count) { YAML.load_file(Rails.root.join('db/seeds/roles.yaml')).size }

    it 'creates the default roles with exactly the permissions named in db/seeds/roles.yaml' do
      expect { seed_maker.seed_roles }.to change(Role, :count).by(default_role_count)

      developer = Role.find_by(name: 'Open Path Developer')
      expect(developer.can_edit_roles).to be true
      expect(developer.can_delete_data_sources).to be true
      # not in the developer's list; a role that grants everything would be a real access problem
      expect(developer.can_view_clients).to be false
    end

    it 'does not touch an existing role, which may have been tuned in the UI' do
      create(:role, name: 'Open Path Developer', can_edit_roles: false, can_view_clients: true)

      expect { seed_maker.seed_roles }.to change(Role, :count).by(default_role_count - 1)

      developer = Role.find_by(name: 'Open Path Developer')
      expect(developer.can_edit_roles).to be false
      expect(developer.can_view_clients).to be true
    end

    it 'is a no-op once more than three roles exist' do
      4.times { |i| create(:role, name: "existing #{i}") }

      expect { seed_maker.seed_roles }.not_to change(Role, :count)
      expect(Role.find_by(name: 'Open Path Developer')).to be_nil
    end

    it 'reset_permissions rewrites an existing role to the yaml, clearing permissions it does not name' do
      4.times { |i| create(:role, name: "existing #{i}") }
      create(:role, name: 'Report Runner', can_edit_roles: true, enforced_2fa: false)

      seed_maker.seed_roles(reset_permissions: true)

      runner = Role.find_by(name: 'Report Runner')
      expect(runner.enforced_2fa).to be true
      expect(runner.can_edit_roles).to be false
    end
  end

  describe '#production_seed_first_user' do
    it 'grants the new user developer permissions over all data sources' do
      user = seed_maker.production_seed_first_user(email: 'seeded@example.com', first_name: 'Sample', last_name: 'Admin')

      expect(user).to be_active
      expect(user.permission_context).to eq('acls')
      expect(UserGroup.find_by(name: 'Open Path Developers').users).to include(user)
      expect(
        AccessControl.find_by(
          role: Role.find_by(name: 'Open Path Developer'),
          collection: Collection.system_collection(:data_sources),
          user_group: UserGroup.find_by(name: 'Open Path Developers'),
        ),
      ).to be_present
      expect(user.can_edit_data_sources?).to be true
      expect(user.can_view_clients?).to be false
    end

    # CI's default arm is jwt, so this is the only coverage of the Devise branch in
    # production_seed_first_user: the seeded admin needs a generated password and a confirmed_at, or
    # they cannot sign in on a new deployment.
    it 'sets a password and confirms the user', :devise_only do
      user = seed_maker.production_seed_first_user(email: 'seeded@example.com', first_name: 'Sample', last_name: 'Admin')

      expect(user.encrypted_password).to be_present
      expect(user.confirmed_at).to be_present
    end

    it 'refuses to re-seed over an existing email rather than granting a second developer ACL' do
      seed_maker.production_seed_first_user(email: 'seeded@example.com', first_name: 'Sample', last_name: 'Admin')

      expect do
        expect { seed_maker.production_seed_first_user(email: 'seeded@example.com', first_name: 'Other', last_name: 'Admin') }.
          to raise_error(/already exists/)
      end.not_to change(AccessControl, :count)
    end
  end
end
