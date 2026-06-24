###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# The credential-building keycloak migration tasks read User#otp_secret, an
# accessor the :two_factor_authenticatable Devise macro provides only under
# AUTH_METHOD=devise. These specs prove the AUTH_METHOD guard fires before any
# service configuration / credential work, so a post-flip run aborts cleanly
# instead of crashing mid-batch on the first 2FA user.
RSpec.describe 'keycloak credential migration tasks', type: :task do
  # All three tasks that touch User credentials should be gated. import_users
  # (reads a pre-built JSON file) and test_connection are intentionally excluded.
  guarded_tasks = ['keycloak:migrate_users', 'keycloak:export_users', 'keycloak:import_single_user']

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'keycloak:migrate_users' }
  end

  before do
    guarded_tasks.each { |name| Rake::Task[name].reenable }
  end

  guarded_tasks.each do |task_name|
    describe task_name do
      context 'under AUTH_METHOD=jwt' do
        before do
          allow(AuthMethod).to receive(:devise?).and_return(false)
          allow(AuthMethod).to receive(:jwt?).and_return(true)
          allow(Idp::ServiceFactory).to receive(:for_connector)
        end

        it 'aborts before configuring the Keycloak service' do
          expect { Rake::Task[task_name].invoke }.to raise_error(SystemExit)
          # Never reaches keycloak_importer, so no credential accessor is touched.
          expect(Idp::ServiceFactory).not_to have_received(:for_connector)
        end
      end

      context 'under AUTH_METHOD=devise' do
        before do
          allow(AuthMethod).to receive(:devise?).and_return(true)
          allow(AuthMethod).to receive(:jwt?).and_return(false)
          # Return a non-Keycloak service so the task stops at the existing
          # "not configured" check — far enough to prove the guard let it pass,
          # without performing a real migration.
          allow(Idp::ServiceFactory).to receive(:for_connector).and_return(nil)
          # import_single_user reaches its service config only after a user
          # lookup; satisfy that without hitting the DB. (Unused by the others.)
          allow(User).to receive(:find_by).and_return(instance_double(User))
        end

        it 'passes the guard and proceeds to configure the Keycloak service' do
          expect { Rake::Task[task_name].invoke('a@example.com') }.to raise_error(SystemExit)
          expect(Idp::ServiceFactory).to have_received(:for_connector).with('keycloak')
        end
      end
    end
  end
end
