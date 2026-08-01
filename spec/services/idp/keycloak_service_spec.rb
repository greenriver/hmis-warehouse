###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe Idp::KeycloakService, type: :model do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:client_id) { 'rails-service-account' }
  let(:client_secret) { 'test-secret' }
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let(:service) do
    described_class.new(
      config: {
        api_url: api_url,
        realm: realm,
        client_id: client_id,
        client_secret: client_secret,
      },
    )
  end

  before do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).
      to_return(
        status: 200,
        body: { access_token: 'test-token', expires_in: 300 }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )
  end

  after do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  describe '#create_user' do
    let(:user_email) { 'test@example.com' }

    context 'with valid user data' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(
            status: 201,
            headers: { 'Location' => "#{api_url}/admin/realms/#{realm}/users/new-user-id" },
          )
      end

      it 'creates user and returns success with user ID' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to eq('new-user-id')
      end

      it 'sends the Keycloak user payload with the expected field mapping' do
        service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(
          a_request(:post, "#{api_url}/admin/realms/#{realm}/users").
            with(
              headers: { 'Authorization' => 'Bearer test-token' },
              body: {
                username: user_email,
                email: user_email,
                firstName: 'John',
                lastName: 'Doe',
                enabled: true,
                emailVerified: false,
              },
            ),
        ).to have_been_made
      end
    end

    context 'with a 201 response missing the Location header' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(status: 201)
      end

      it 'returns success with a nil connector_user_id rather than raising' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to be_nil
      end
    end

    # ConflictError, not the plain ServiceError it descends from: the admin controller
    # rescues the two separately, putting a conflict on the email field and paging on
    # anything else. Asserting the parent class here would pass either way.
    context 'when the address already belongs to an account in the realm' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(
            status: 409,
            body: { errorMessage: 'User exists with same username' }.to_json,
          )
      end

      it 'raises ConflictError' do
        expect do
          service.create_user(
            email: user_email,
            first_name: 'John',
            last_name: 'Doe',
          )
        end.to raise_error(Idp::ConflictError, /Failed to create user: User exists with same username/)
      end
    end

    context 'with a non-conflict API error' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(
            status: 400,
            body: { errorMessage: 'Invalid email' }.to_json,
          )
      end

      # The other half of the distinction: a broken write must not arrive as a form problem.
      it 'raises a bare ServiceError rather than ConflictError' do
        expect do
          service.create_user(
            email: user_email,
            first_name: 'John',
            last_name: 'Doe',
          )
        end.to raise_error(Idp::ServiceError, /Failed to create user: Invalid email/) { |error|
          expect(error).not_to be_a(Idp::ConflictError)
        }
      end
    end
  end

  describe '#find_user_by_email' do
    let(:email) { 'jane@example.com' }
    let(:search_url) { "#{api_url}/admin/realms/#{realm}/users" }

    it 'queries by exact email and returns the matching representation' do
      stub_request(:get, search_url).
        with(query: { email: email, exact: 'true' }).
        to_return(status: 200, body: [{ id: 'kc-1', email: email }].to_json)

      result = service.find_user_by_email(email: email)

      expect(result['id']).to eq('kc-1')
    end

    it 'returns nil when no user matches' do
      stub_request(:get, search_url).
        with(query: { email: email, exact: 'true' }).
        to_return(status: 200, body: [].to_json)

      expect(service.find_user_by_email(email: email)).to be_nil
    end
  end

  describe '#send_execute_actions_email' do
    let(:user_id) { 'kc-user-id' }
    let(:actions_url) { "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email" }

    it 'PUTs the required actions and returns true on 204' do
      stub_request(:put, actions_url).to_return(status: 204)

      result = service.send_execute_actions_email(user_id: user_id, actions: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'])

      expect(result).to be true
      expect(
        a_request(:put, actions_url).with(body: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'].to_json),
      ).to have_been_made
    end

    it 'raises a delivery-focused ServiceError, not a raw status code, when Keycloak fails to send (e.g. bad address or SMTP not configured)' do
      stub_request(:put, actions_url).to_return(status: 500, body: { errorMessage: 'Failed to send email' }.to_json)

      expect do
        service.send_execute_actions_email(user_id: user_id, actions: ['UPDATE_PASSWORD'])
      end.to raise_error(Idp::ServiceError, /couldn't deliver it.*email address is valid/)
    end
  end

  describe '#update_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) do
      { id: user_id, username: 'jane', firstName: 'Old', lastName: 'Name', email: 'old@example.com' }
    end

    context 'with successful update' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and sends the full representation with the mapped attribute merged in' do
        result = service.update_user(
          user_id: user_id,
          attributes: { first_name: 'Jane' },
        )

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(firstName: 'Jane')),
        ).to have_been_made
      end

      it 'sets emailVerified to false when the email changes and leaves username for Keycloak to derive, without clearing other fields' do
        actions_url = "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        stub_request(:put, actions_url).to_return(status: 204)

        service.update_user(
          user_id: user_id,
          attributes: { email: 'new@example.com' },
        )

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(email: 'new@example.com', emailVerified: false)),
        ).to have_been_made
      end

      it 'sends a verification email when the email changes' do
        actions_url = "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        stub_request(:put, actions_url).to_return(status: 204)

        service.update_user(
          user_id: user_id,
          attributes: { email: 'new@example.com' },
        )

        expect(
          a_request(:put, actions_url).with(body: ['VERIFY_EMAIL'].to_json),
        ).to have_been_made
      end

      it 'does not send a verification email or touch username when email is unchanged' do
        service.update_user(
          user_id: user_id,
          attributes: { first_name: 'Jane' },
        )

        expect(WebMock).not_to have_requested(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email")
      end

      it 'carries fields the patch never references (custom attributes, requiredActions) through the merge' do
        full_representation = current_representation.merge(
          attributes: { department: ['Housing'] },
          requiredActions: ['CONFIGURE_TOTP'],
        )
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: full_representation.to_json)

        service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: full_representation.merge(firstName: 'Jane')),
        ).to have_been_made
      end
    end

    context 'with unknown attributes' do
      it 'raises ArgumentError' do
        expect do
          service.update_user(
            user_id: user_id,
            attributes: { first_name: 'Jane', phone: '555-1234' },
          )
        end.to raise_error(ArgumentError, /phone/)
      end
    end

    context 'with empty attributes' do
      it 'returns true without making a request' do
        result = service.update_user(user_id: user_id, attributes: {})

        expect(result).to be true
        expect(WebMock).not_to have_requested(:get, /#{Regexp.escape(api_url)}/)
        expect(WebMock).not_to have_requested(:put, /#{Regexp.escape(api_url)}/)
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 400,
            body: { errorMessage: 'Invalid attribute' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.update_user(
            user_id: user_id,
            attributes: { first_name: 'Jane' },
          )
        end.to raise_error(Idp::ServiceError, /Failed to update user: Invalid attribute/)
      end
    end

    # The controller's other ConflictError path: the address belongs to another account in
    # the realm rather than the connector being broken.
    context 'when the new address is already registered to another account' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 409,
            body: { errorMessage: 'User exists with same email' }.to_json,
          )
      end

      it 'raises ConflictError' do
        expect do
          service.update_user(user_id: user_id, attributes: { email: 'taken@example.com' })
        end.to raise_error(Idp::ConflictError, /Failed to update user: User exists with same email/)
      end

      it 'does not send a verification email for a write that never landed' do
        actions_url = "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        stub_request(:put, actions_url).to_return(status: 204)

        expect do
          service.update_user(user_id: user_id, attributes: { email: 'taken@example.com' })
        end.to raise_error(Idp::ConflictError)

        expect(WebMock).not_to have_requested(:put, actions_url)
      end
    end

    # Keycloak holds the new address before the mail goes out, so a delivery failure must not
    # propagate: the caller would unwind its local write and diverge in the direction no retry
    # can close.
    context 'when the verification email cannot be delivered' do
      let(:actions_url) { "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email" }

      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
        stub_request(:put, actions_url).
          to_return(status: 500, body: { errorMessage: 'Failed to send email' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still reports the update as successful' do
        expect(service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })).to be true
      end

      it 'leaves the address change committed at Keycloak' do
        service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(email: 'new@example.com', emailVerified: false)),
        ).to have_been_made
      end

      # Swallowed, not dropped: nobody sees the failure unless it is reported.
      it 'reports the swallowed delivery failure' do
        service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })

        expect(Sentry).to have_received(:capture_exception_with_info).
          with(instance_of(Idp::ServiceError), /couldn't send the address verification email/)
      end

      # Only the mail leg is forgiven. A failed write still has to reach the caller.
      it 'does not swallow a failure from the profile write itself' do
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 400, body: { errorMessage: 'Invalid attribute' }.to_json)

        expect do
          service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })
        end.to raise_error(Idp::ServiceError, /Failed to update user/)
      end
    end

    context 'when the user cannot be fetched first' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 404)
      end

      it 'raises ServiceError from the GET instead of PUTting a partial body' do
        expect do
          service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })
        end.to raise_error(Idp::ServiceError, /User not found/)
        expect(WebMock).not_to have_requested(:put, /#{Regexp.escape(api_url)}/)
      end
    end
  end

  describe '#get_user' do
    let(:user_id) { 'keycloak-user-id' }

    context 'with successful response' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 200,
            body: { id: user_id, username: 'test@example.com' }.to_json,
          )
      end

      it 'returns user data' do
        result = service.get_user(user_id: user_id)

        expect(result).to include('id' => user_id)
      end
    end

    context 'when user not found' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 404)
      end

      it 'raises ServiceError' do
        expect do
          service.get_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /User not found: #{user_id}/)
      end
    end
  end

  # Keycloak parks the unconfirmed address in an internal user attribute
  describe '#pending_email' do
    let(:user_id) { 'keycloak-user-id' }

    def stub_representation(attributes)
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 200, body: { id: user_id, email: 'before@example.com' }.merge(attributes).to_json)
    end

    it 'returns the address awaiting confirmation' do
      stub_representation(attributes: { 'kc.email.pending' => ['after@example.com'] })

      expect(service.pending_email(user_id: user_id)).to eq('after@example.com')
    end

    it 'returns nil when no change is in flight' do
      stub_representation(attributes: { 'someOther' => ['x'] })

      expect(service.pending_email(user_id: user_id)).to be_nil
    end

    it 'returns nil for a user with no attributes at all' do
      stub_representation({})

      expect(service.pending_email(user_id: user_id)).to be_nil
    end
  end

  describe '#reactivate_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with successful reactivation' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and enables the user without clearing other fields' do
        result = service.reactivate_user(user_id: user_id)

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(enabled: true)),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.reactivate_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /Failed to reactivate user: User not found/)
      end
    end
  end

  describe '#deactivate_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with successful deactivation' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and disables the user without clearing other fields' do
        result = service.deactivate_user(user_id: user_id)

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(enabled: false)),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.deactivate_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /Failed to deactivate user: User not found/)
      end
    end
  end

  describe '#set_required_action' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with a successful update' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and sets the required actions without clearing other fields' do
        result = service.set_required_action(user_id: user_id, actions: ['UPDATE_PASSWORD'])

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(requiredActions: ['UPDATE_PASSWORD'])),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.set_required_action(user_id: user_id, actions: ['UPDATE_PASSWORD'])
        end.to raise_error(Idp::ServiceError, /Failed to set required actions: User not found/)
      end
    end
  end

  describe '#test_connection' do
    context 'with successful connection' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(
            status: 200,
            body: { realm: realm }.to_json,
          )
      end

      it 'returns success result' do
        result = service.test_connection

        expect(result[:success]).to be true
        expect(result[:message]).to include('Connection successful')
      end
    end

    context 'with authentication failure' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 401)
      end

      it 'returns failure with auth message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Authentication failed')
      end
    end

    context 'with endpoint not found' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 404)
      end

      it 'returns failure with an endpoint-not-found message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('API endpoint not found')
      end
    end

    context 'with a Keycloak server error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 500)
      end

      it 'returns failure with the server error message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Keycloak server error: 500')
      end
    end

    context 'with connection refused' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_raise(Errno::ECONNREFUSED)
      end

      it 'returns failure with connection message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Connection refused')
      end
    end

    context 'with host unreachable' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_raise(Errno::EHOSTUNREACH)
      end

      it 'returns failure with a host-unreachable message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Host unreachable')
      end
    end

    context 'with timeout' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_timeout
      end

      it 'returns failure with timeout message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('timeout')
      end
    end
  end

  describe 'token retry on 401' do
    let(:user_id) { 'keycloak-user-id' }

    it 'retries once with a fresh token when API returns 401' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(
          { status: 401, body: { error: 'invalid_token' }.to_json },
          { status: 200, body: { id: user_id, username: 'test@example.com' }.to_json },
        )

      result = service.get_user(user_id: user_id)

      expect(result).to include('id' => user_id)
      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end

    it 'does not retry more than once' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 401, body: { error: 'invalid_token' }.to_json)

      expect do
        service.get_user(user_id: user_id)
      end.to raise_error(Idp::ServiceError, /Failed to get user/)
      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end
  end

  # Every call goes out behind this exchange, and the token stub these examples inherit matches
  # any body, so nothing else here would notice the credentials going out wrong.
  describe 'the client-credentials token exchange' do
    let(:user_id) { 'keycloak-user-id' }

    it 'posts the service account credentials to the realm token endpoint' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 200, body: { id: user_id }.to_json)

      service.get_user(user_id: user_id)

      expect(
        a_request(:post, token_url).
          with(
            headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
            body: {
              grant_type: 'client_credentials',
              client_id: client_id,
              client_secret: client_secret,
            },
          ),
      ).to have_been_made
    end

    it 'sends the token it was issued, not a blank bearer' do
      stub_request(:post, token_url).
        to_return(
          status: 200,
          body: { access_token: 'issued-token', expires_in: 300 }.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 200, body: { id: user_id }.to_json)

      service.get_user(user_id: user_id)

      expect(
        a_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          with(headers: { 'Authorization' => 'Bearer issued-token' }),
      ).to have_been_made
    end

    context 'when the token endpoint rejects the credentials' do
      before do
        stub_request(:post, token_url).
          to_return(status: 401, body: { error: 'invalid_client' }.to_json)
      end

      it 'raises rather than calling the Admin API unauthenticated' do
        expect do
          service.get_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /Failed to obtain access token: 401/)

        expect(WebMock).not_to have_requested(:get, /#{Regexp.escape(api_url)}\/admin/)
      end

      it 'tags the failure with the operation that produced it' do
        error = begin
          service.get_user(user_id: user_id)
        rescue Idp::ServiceError => e
          e
        end

        expect(error.operation).to eq(:access_token)
        expect(error.idp_name).to eq('Keycloak')
      end
    end
  end

  describe 'token caching' do
    let(:user_id) { 'keycloak-user-id' }

    before do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 200, body: { id: user_id, username: 'test@example.com' }.to_json)
    end

    it 'reuses the cached token across requests instead of fetching a new one each time' do
      service.get_user(user_id: user_id)
      service.get_user(user_id: user_id)

      expect(a_request(:post, token_url)).to have_been_made.once
    end

    it 'fetches a new token once the cached one has expired' do
      service.get_user(user_id: user_id)

      travel(6.minutes) do
        service.get_user(user_id: user_id)
      end

      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end
  end

  describe '#idp_name' do
    it 'returns Keycloak' do
      expect(service.idp_name).to eq('Keycloak')
    end
  end

  describe '#supports_user_management?' do
    it 'returns true when fully configured' do
      expect(service.supports_user_management?).to be true
    end
  end

  describe '#supports_account_backfill?' do
    it 'returns true (the backfill runs against Keycloak)' do
      expect(service.supports_account_backfill?).to be true
    end

    it 'defaults to false on a service without a manageable admin API' do
      expect(Idp::NullService.new('keycloak').supports_account_backfill?).to be false
    end
  end

  describe 'config validation' do
    it 'raises on missing api_url' do
      expect do
        described_class.new(config: { client_id: 'x', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /api_url/)
    end

    it 'raises on missing realm (no default)' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', client_id: 'x', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /realm/)
    end

    it 'raises on missing client_id' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', realm: 'r', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /client_id/)
    end

    it 'raises on missing client_secret' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', realm: 'r', client_id: 'x' })
      end.to raise_error(Idp::ServiceError, /client_secret/)
    end

    it 'lists all missing keys' do
      expect do
        described_class.new(config: {})
      end.to raise_error(Idp::ServiceError, /api_url, realm, client_id, client_secret/)
    end
  end

  describe '.from_config' do
    # Mirrors the Idp::ServiceConfig reader surface that .from_config consumes
    # (api_url, client_id, service_token, keycloak_realm) without needing the DB
    # or encryption key. ServiceConfig's own columns are covered by its spec.
    let(:persisted_config) do
      Struct.new(:api_url, :client_id, :service_token, :keycloak_realm, keyword_init: true).new(
        api_url: 'http://kc.from-config:8080',
        client_id: 'config-client',
        service_token: 'config-secret',
        keycloak_realm: 'config-realm',
      )
    end

    it 'translates persisted storage columns into the service config keys' do
      service = described_class.from_config(persisted_config)

      expect(service.config).to include(
        api_url: 'http://kc.from-config:8080',
        client_id: 'config-client',
        client_secret: 'config-secret',
        realm: 'config-realm',
      )
    end
  end

  describe '#supports_profile_updates?' do
    it 'returns true' do
      expect(service.supports_profile_updates?).to be true
    end
  end

  describe '#supports_email_self_service?' do
    it 'asserts true without probing the realm for the Update Email required action' do
      expect(service.supports_email_self_service?).to be true
      expect(a_request(:any, /#{Regexp.escape(api_url)}/)).not_to have_been_made
    end
  end

  describe '#account_console_url' do
    it 'builds the Account Console URL for the realm' do
      expect(service.account_console_url).to eq("#{api_url}/realms/#{realm}/account")
    end

    context 'when API URL is not configured' do
      before do
        service.config[:api_url] = nil
      end

      it 'returns nil' do
        expect(service.account_console_url).to be_nil
      end
    end
  end

  describe '#account_action_url' do
    let(:redirect_uri) { 'https://warehouse.test/account/edit' }

    subject(:url) { service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: redirect_uri) }

    it 'targets the realm authorize endpoint' do
      expect(url).to start_with("#{api_url}/realms/#{realm}/protocol/openid-connect/auth?")
    end

    it 'carries the action, client, redirect, and OIDC params' do
      query = Rack::Utils.parse_query(URI(url).query)
      expect(query).to include(
        'kc_action' => 'UPDATE_PASSWORD',
        'client_id' => 'account',
        'redirect_uri' => redirect_uri,
        'response_type' => 'code',
        'scope' => 'openid',
      )
    end

    # The client's Base URL is where Keycloak sends the user back from an out-of-band confirmation
    # link, so which client the action runs under decides where an email change lands.
    describe 'the client the action runs under' do
      def client_id_in(url)
        Rack::Utils.parse_query(URI(url).query)['client_id']
      end

      it 'runs under the configured account client' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('KEYCLOAK_ACCOUNT_CLIENT_ID').and_return('warehouse-account')

        expect(client_id_in(url)).to eq('warehouse-account')
      end

      # Nothing sets this key yet; a per-realm column would, and it beats ENV.
      it 'prefers a config key over the ENV value' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('KEYCLOAK_ACCOUNT_CLIENT_ID').and_return('ignored')
        service.config[:account_client_id] = 'from-config'

        expect(client_id_in(url)).to eq('from-config')
      end

      # Keycloak's own account client returns the user to the Keycloak account console rather than
      # here, but it exists on every realm — a wrong destination beats a dead link.
      it 'falls back to the built-in account client when nothing is configured' do
        expect(client_id_in(url)).to eq('account')
      end
    end

    context 'when API URL is not configured' do
      before do
        service.config[:api_url] = nil
      end

      it 'returns nil' do
        expect(url).to be_nil
      end
    end
  end

  # Back channel rather than an RP-initiated logout redirect: the app is handed Dex's id_token, not
  # Keycloak's, so there's no id_token_hint to send. The Admin API doesn't need one.
  describe '#logout_user_sessions' do
    let(:logout_path) { "#{api_url}/admin/realms/#{realm}/users/abc/logout" }

    it 'POSTs to the user logout endpoint with the service-account token' do
      stub_request(:post, logout_path).to_return(status: 204)

      expect(service.logout_user_sessions(user_id: 'abc')).to eq(true)
      expect(a_request(:post, logout_path).with(headers: { 'Authorization' => 'Bearer test-token' })).to have_been_made
    end

    # The service account can hold manage-users for reads/writes and still be refused here.
    it 'raises when the service account is not authorized for it' do
      stub_request(:post, logout_path).to_return(
        status: 403,
        body: { errorMessage: 'Forbidden' }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )

      expect { service.logout_user_sessions(user_id: 'abc') }.
        to raise_error(Idp::ServiceError, /Failed to end IDP sessions/)
    end

    it 'raises when the user id is unknown to the realm' do
      stub_request(:post, logout_path).to_return(status: 404, body: '')

      expect { service.logout_user_sessions(user_id: 'abc') }.
        to raise_error(Idp::ServiceError, /Failed to end IDP sessions/)
    end

    it 'raises rather than returning quietly when Keycloak is unreachable' do
      stub_request(:post, logout_path).to_timeout

      expect { service.logout_user_sessions(user_id: 'abc') }.to raise_error(StandardError)
    end

    it 'is advertised by the capability predicate' do
      expect(service.supports_session_logout?).to eq(true)
    end

    # Sign-out fails closed on a false-y capability meaning "nothing to attempt", so an
    # unconfigured connector has to answer false rather than true-then-raise. Otherwise a blank
    # api_url stops everyone on the connector from signing out at all.
    it 'is not advertised when the service has no api_url to reach' do
      service.config[:api_url] = nil

      expect(service.supports_session_logout?).to eq(false)
    end
  end

  # Browser links come off the public URL; Admin API calls must not.
  describe 'the browser-facing URL override' do
    let(:public_url) { 'https://keycloak.public.test' }

    shared_examples 'honors the browser URL' do
      it 'builds the account console URL from it' do
        expect(service.account_console_url).to eq("#{public_url}/realms/#{realm}/account")
      end

      it 'builds account action deep-links from it' do
        url = service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: 'https://warehouse.test/account/edit')

        expect(url).to start_with("#{public_url}/realms/#{realm}/protocol/openid-connect/auth?")
      end

      it 'leaves Admin API calls on api_url' do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/abc").
          to_return(status: 200, body: { id: 'abc' }.to_json, headers: { 'Content-Type' => 'application/json' })

        service.get_user(user_id: 'abc')

        expect(a_request(:get, "#{api_url}/admin/realms/#{realm}/users/abc")).to have_been_made
        expect(a_request(:any, /#{Regexp.escape(public_url)}/)).not_to have_been_made
      end
    end

    context 'supplied by ENV' do
      before { stub_const('ENV', ENV.to_h.merge('KEYCLOAK_PUBLIC_URL' => public_url)) }

      include_examples 'honors the browser URL'
    end

    # Nothing sets this key yet; a per-realm column would, and it beats ENV.
    context 'supplied in the config hash' do
      before do
        stub_const('ENV', ENV.to_h.merge('KEYCLOAK_PUBLIC_URL' => 'https://ignored.test'))
        service.config[:browser_url] = public_url
      end

      include_examples 'honors the browser URL'
    end

    context 'when api_url is not configured' do
      before do
        stub_const('ENV', ENV.to_h.merge('KEYCLOAK_PUBLIC_URL' => public_url))
        service.config[:api_url] = nil
      end

      it 'stays unconfigured rather than answering from the override alone' do
        expect(service.account_console_url).to be_nil
        expect(service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: 'https://warehouse.test/x')).to be_nil
      end
    end
  end

  describe '#each_user' do
    let(:users_url) { "#{api_url}/admin/realms/#{realm}/users" }

    def stub_page(first, max, users)
      stub_request(:get, users_url).
        with(query: { first: first.to_s, max: max.to_s }).
        to_return(
          status: 200,
          body: users.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
    end

    it 'pages past the first full page and stops on the final short page' do
      page1 = Array.new(2) { |i| { 'id' => "id-#{i}", 'email' => "u#{i}@example.com" } }
      page2 = [{ 'id' => 'id-2', 'email' => 'u2@example.com' }]
      stub_page(0, 2, page1)
      stub_page(2, 2, page2)

      collected = service.each_user(page_size: 2).to_a

      expect(collected).to eq(
        [
          { email: 'u0@example.com', id: 'id-0' },
          { email: 'u1@example.com', id: 'id-1' },
          { email: 'u2@example.com', id: 'id-2' },
        ],
      )
    end

    it 'stops when a full page is followed by an empty page' do
      stub_page(0, 2, [{ 'id' => 'a', 'email' => 'a@x.com' }, { 'id' => 'b', 'email' => 'b@x.com' }])
      stub_page(2, 2, [])

      expect(service.each_user(page_size: 2).to_a.size).to eq(2)
    end
  end

  describe 'HTTP timeouts' do
    # build_http is private and WebMock stands in for the socket, so record what the service had set
    # on the connection each request went out on. Keyed by path because a call also fetches a token,
    # on its own connection with its own budget.
    let(:sent) { {} }

    before do
      recorded = sent
      allow_any_instance_of(Net::HTTP).to receive(:request).and_wrap_original do |original, *args|
        http = original.receiver
        (recorded[args.first.path] ||= []) << [http.open_timeout, http.read_timeout, http.write_timeout]
        original.call(*args)
      end
    end

    # One entry per request sent to `path`, oldest first, each [open, read, write].
    def timeouts_of(path)
      sent.fetch(path)
    end

    let(:default_timeouts) do
      [described_class::OPEN_TIMEOUT_SECONDS, described_class::IO_TIMEOUT_SECONDS, described_class::IO_TIMEOUT_SECONDS]
    end

    let(:bulk_timeouts) do
      [described_class::OPEN_TIMEOUT_SECONDS, described_class::BULK_IO_TIMEOUT_SECONDS, described_class::BULK_IO_TIMEOUT_SECONDS]
    end

    it 'gives an ordinary call the short defaults' do
      stub_request(:post, "#{api_url}/admin/realms/#{realm}/users/user-1/logout").to_return(status: 204)

      service.logout_user_sessions(user_id: 'user-1')

      expect(timeouts_of("/admin/realms/#{realm}/users/user-1/logout")).to eq([default_timeouts])
      # The token round trip a call makes on the way is on the default budget too.
      expect(timeouts_of("/realms/#{realm}/protocol/openid-connect/token")).to eq([default_timeouts])
    end

    it 'gives a bulk call a longer read and write budget' do
      stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").to_return(status: 200, body: '{}')

      service.partial_import({ users: [] })

      expect(timeouts_of("/admin/realms/#{realm}/partialImport")).to eq([bulk_timeouts])
    end

    it 'keeps the longer budget on the 401 token retry' do
      stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
        to_return({ status: 401 }, { status: 200, body: '{}' })

      service.partial_import({ users: [] })

      expect(timeouts_of("/admin/realms/#{realm}/partialImport")).to eq([bulk_timeouts, bulk_timeouts])
    end

    it 'gives the paginated user listing the longer budget' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users").
        with(query: { first: '0', max: '100' }).
        to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      service.each_user.to_a

      expect(timeouts_of("/admin/realms/#{realm}/users?first=0&max=100")).to eq([bulk_timeouts])
    end
  end

  describe '#ensure_group' do
    let(:groups_url) { "#{api_url}/admin/realms/#{realm}/groups" }

    it 'returns :created when Keycloak creates the group' do
      stub_request(:post, groups_url).
        with(body: { name: 'warehouse-users' }.to_json).
        to_return(status: 201)

      expect(service.ensure_group('warehouse-users')).to eq(:created)
    end

    it 'returns :existing when the group already exists (409)' do
      stub_request(:post, groups_url).
        with(body: { name: 'warehouse-users' }.to_json).
        to_return(status: 409, body: { errorMessage: 'Top level group named warehouse-users already exists.' }.to_json)

      expect(service.ensure_group('warehouse-users')).to eq(:existing)
    end

    it 'raises ServiceError on an unexpected response' do
      stub_request(:post, groups_url).
        to_return(status: 500, body: { errorMessage: 'boom' }.to_json)

      expect { service.ensure_group('warehouse-users') }.
        to raise_error(Idp::ServiceError, /boom/)
    end
  end
end
