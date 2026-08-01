###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::NullService, type: :model do
  let(:service) { described_class.new }

  # Every management method has to raise Idp::ServiceError specifically. Callers rescue that class and
  # nothing wider, so a method that fell through to Idp::Service and raised NotImplementedError would
  # escape their soft-failure handling and 500 the request. `operation` is also what tells get_user's
  # raise apart from find_user_by_email's, since the two share a message.
  #
  # send_execute_actions_email has no capability predicate in front of it: Idp::Support#idp_send_account_setup_email!
  # gates only on primary_idp, so the raise is the sole guard.
  describe 'management methods' do
    {
      create_user: ['User management not supported', { email: 'test@example.com', first_name: 'Test', last_name: 'User' }],
      update_user: ['Profile updates not supported', { user_id: 'user-123', attributes: { first_name: 'John' } }],
      get_user: ['User lookup not supported', { user_id: 'user-123' }],
      find_user_by_email: ['User lookup not supported', { email: 'test@example.com' }],
      send_execute_actions_email: ['Account setup email not supported', { user_id: 'user-123', actions: ['UPDATE_PASSWORD'] }],
      reactivate_user: ['User reactivation not supported', { user_id: 'user-123' }],
      deactivate_user: ['User deactivation not supported', { user_id: 'user-123' }],
      set_required_action: ['Required actions not supported', { user_id: 'user-123', actions: ['UPDATE_PASSWORD'] }],
      # supports_session_logout? means nothing should reach this. If something does it must be loud,
      # not a silent no-op that reads as "the IdP session was ended".
      logout_user_sessions: ['Session logout not supported', { user_id: 'user-123' }],
    }.each do |method, (message, args)|
      describe "##{method}" do
        it 'raises ServiceError tagged with the operation and the IdP name' do
          expect { service.public_send(method, **args) }.to raise_error(Idp::ServiceError) do |error|
            expect(error.message).to eq(message)
            expect(error.operation).to eq(method)
            # Admin::Idp::UsersController interpolates this into user-facing form copy.
            expect(error.idp_name).to eq('Unknown IDP')
          end
        end

        it 'carries the humanized connector_id as the IdP name when there is one' do
          expect { described_class.new('keycloak').public_send(method, **args) }.
            to raise_error(Idp::ServiceError) { |error| expect(error.idp_name).to eq('Keycloak') }
        end
      end
    end
  end

  describe '#idp_name' do
    it 'returns Unknown IDP when no connector_id' do
      expect(service.idp_name).to eq('Unknown IDP')
    end

    it 'humanizes connector_id when provided' do
      service_with_connector = described_class.new('keycloak')
      expect(service_with_connector.idp_name).to eq('Keycloak')
    end
  end

  # These gates keep admin and self-service surfaces from offering an action the null IdP cannot
  # perform, and NullService inherits the defaults, so flipping one to true in Idp::Service would
  # otherwise go unnoticed here. supports_user_creation? is what stands between an unconfigured
  # connector and Idp::AdminUserCreator provisioning against it.
  describe 'capability predicates' do
    [
      :supports_user_management?,
      :supports_user_creation?,
      :supports_profile_updates?,
      :supports_email_self_service?,
      :supports_account_backfill?,
      :supports_session_logout?,
    ].each do |predicate|
      it "answers false to ##{predicate}" do
        expect(service.public_send(predicate)).to be false
      end
    end
  end

  describe '#account_console_url' do
    it 'returns nil' do
      expect(service.account_console_url).to be_nil
    end
  end

  describe 'initialization' do
    it 'accepts optional connector_id' do
      service = described_class.new('custom_idp')
      expect(service.connector_id).to eq('custom_idp')
    end

    it 'has empty config' do
      expect(service.config).to eq({})
    end
  end
end

RSpec.describe Idp::Service, type: :model do
  describe '#account_console_url' do
    it 'defaults to nil on the base contract' do
      expect(described_class.new.account_console_url).to be_nil
    end
  end

  describe '#supports_email_self_service?' do
    it 'defaults to false on the base contract' do
      expect(described_class.new.supports_email_self_service?).to be false
    end
  end

  describe '#supports_session_logout?' do
    it 'defaults to false on the base contract' do
      expect(described_class.new.supports_session_logout?).to be false
    end
  end

  describe '#logout_user_sessions' do
    it 'raises NotImplementedError on the base contract' do
      expect do
        described_class.new.logout_user_sessions(user_id: 'user-123')
      end.to raise_error(NotImplementedError, /must implement #logout_user_sessions/)
    end
  end
end
