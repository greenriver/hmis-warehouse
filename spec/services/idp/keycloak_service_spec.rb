###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::KeycloakService do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:client_id) { 'rails-service-account' }
  let(:client_secret) { 'test-secret' }
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }
  let(:user_id) { 'keycloak-user-id' }

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

  def admin_url(path = '')
    "#{api_url}/admin/realms/#{realm}#{path}"
  end

  def user_url(id = user_id)
    admin_url("/users/#{id}")
  end

  def actions_url(id = user_id)
    "#{user_url(id)}/execute-actions-email"
  end

  # Any request to the connector, for the "it never went out" assertions.
  def any_api_request
    /#{Regexp.escape(api_url)}/
  end

  # The read-modify-write shape every profile write shares: fetch the representation, PUT it back.
  def stub_read_modify_write(representation:, put_status: 204, put_body: nil)
    stub_request(:get, user_url).to_return(status: 200, body: representation.to_json)
    stub_request(:put, user_url).to_return(status: put_status, body: put_body)
  end

  # Both keys feed fallback chains (#browser_url, #account_client_id) that several examples below
  # read through, so the unconfigured defaults they assert are only meaningful with the keys
  # provably absent. KEYCLOAK_PUBLIC_URL in particular is documented for dev, where a developer who
  # sets it would otherwise turn those examples red over nothing. Contexts that want a value
  # re-stub ENV themselves.
  before do
    stub_const('ENV', ENV.to_h.except('KEYCLOAK_PUBLIC_URL', 'KEYCLOAK_ACCOUNT_CLIENT_ID'))
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
    let(:create_url) { admin_url('/users') }

    def create_user(**overrides)
      service.create_user(**{ email: user_email, first_name: 'John', last_name: 'Doe' }.merge(overrides))
    end

    context 'with valid user data' do
      before do
        stub_request(:post, create_url).
          to_return(
            status: 201,
            headers: { 'Location' => "#{create_url}/new-user-id" },
          )
      end

      it 'creates user and returns success with user ID' do
        result = create_user

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to eq('new-user-id')
      end

      it 'sends the Keycloak user payload with the expected field mapping' do
        create_user

        expect(
          a_request(:post, create_url).
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
      before { stub_request(:post, create_url).to_return(status: 201) }

      it 'returns success with a nil connector_user_id rather than raising' do
        result = create_user

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to be_nil
      end
    end

    # ConflictError, not the plain ServiceError it descends from: the admin controller
    # rescues the two separately, putting a conflict on the email field and paging on
    # anything else. Asserting the parent class here would pass either way.
    context 'when the address already belongs to an account in the realm' do
      before do
        stub_request(:post, create_url).
          to_return(status: 409, body: { errorMessage: 'User exists with same username' }.to_json)
      end

      # Non-transient as well as ConflictError: the address stays taken until somebody changes it
      # over there, and Idp::SyncUserFromIdpJob re-raises transient faults to retry them, so a
      # retryable conflict would page repeatedly over an answer no retry can change.
      it 'raises a non-transient ConflictError' do
        expect { create_user }.
          to raise_error(Idp::ConflictError, /Failed to create user: User exists with same username/) { |error|
            expect(error).not_to be_transient
          }
      end
    end

    context 'with a non-conflict API error' do
      before do
        stub_request(:post, create_url).
          to_return(status: 400, body: { errorMessage: 'Invalid email' }.to_json)
      end

      # The other half of the distinction: a broken write must not arrive as a form problem.
      it 'raises a bare ServiceError rather than ConflictError' do
        expect { create_user }.to raise_error(Idp::ServiceError, /Failed to create user: Invalid email/) { |error|
          expect(error).not_to be_a(Idp::ConflictError)
        }
      end
    end
  end

  describe '#find_user_by_email' do
    let(:email) { 'jane@example.com' }

    def stub_search(users)
      stub_request(:get, admin_url('/users')).
        with(query: { email: email, exact: 'true' }).
        to_return(status: 200, body: users.to_json)
    end

    it 'queries by exact email and returns the matching representation' do
      stub_search([{ id: 'kc-1', email: email }])

      expect(service.find_user_by_email(email: email)['id']).to eq('kc-1')
    end

    it 'returns nil when no user matches' do
      stub_search([])

      expect(service.find_user_by_email(email: email)).to be_nil
    end
  end

  describe '#send_execute_actions_email' do
    let(:user_id) { 'kc-user-id' }

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
    let(:current_representation) do
      { id: user_id, username: 'jane', firstName: 'Old', lastName: 'Name', email: 'old@example.com' }
    end

    context 'with successful update' do
      before { stub_read_modify_write(representation: current_representation) }

      it 'returns true and sends the full representation with the mapped attribute merged in' do
        result = service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })

        expect(result).to be true
        expect(
          a_request(:put, user_url).with(body: current_representation.merge(firstName: 'Jane')),
        ).to have_been_made
      end

      it 'unverifies the address, leaves username for Keycloak to derive, and sends the verification email' do
        stub_request(:put, actions_url).to_return(status: 204)

        service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })

        expect(
          a_request(:put, user_url).
            with(body: current_representation.merge(email: 'new@example.com', emailVerified: false)),
        ).to have_been_made
        expect(a_request(:put, actions_url).with(body: ['VERIFY_EMAIL'].to_json)).to have_been_made
      end

      it 'does not send a verification email when email is unchanged' do
        service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })

        expect(WebMock).not_to have_requested(:put, actions_url)
      end

      # A blank value is a change the caller already committed locally, not an absent one. Returning
      # true without a request would commit their transaction against a Keycloak still holding the
      # old name — so both blank forms have to reach the wire rather than be read as "nothing asked".
      it 'sends a blank or nil value through as a clear' do
        service.update_user(user_id: user_id, attributes: { first_name: '', last_name: nil })

        expect(
          a_request(:put, user_url).with(body: current_representation.merge(firstName: '', lastName: nil)),
        ).to have_been_made
      end

      it 'carries fields the patch never references (custom attributes, requiredActions) through the merge' do
        full_representation = current_representation.merge(
          attributes: { department: ['Housing'] },
          requiredActions: ['CONFIGURE_TOTP'],
        )
        stub_request(:get, user_url).to_return(status: 200, body: full_representation.to_json)

        service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })

        expect(
          a_request(:put, user_url).with(body: full_representation.merge(firstName: 'Jane')),
        ).to have_been_made
      end
    end

    context 'with unknown attributes' do
      it 'raises ArgumentError' do
        expect do
          service.update_user(user_id: user_id, attributes: { first_name: 'Jane', phone: '555-1234' })
        end.to raise_error(ArgumentError, /phone/)
      end
    end

    # The only route to the empty-patch guard now that a blank value counts as a change.
    context 'with empty attributes' do
      it 'returns true without making a request' do
        result = service.update_user(user_id: user_id, attributes: {})

        expect(result).to be true
        expect(WebMock).not_to have_requested(:get, any_api_request)
        expect(WebMock).not_to have_requested(:put, any_api_request)
      end
    end

    # The refused-PUT path is in 'a refused write' below; 'does not swallow a failure from the
    # profile write itself' covers it again with the mail leg in play.

    # The controller's other ConflictError path: the address belongs to another account in
    # the realm rather than the connector being broken.
    context 'when the new address is already registered to another account' do
      before do
        stub_read_modify_write(
          representation: current_representation,
          put_status: 409,
          put_body: { errorMessage: 'User exists with same email' }.to_json,
        )
      end

      it 'raises ConflictError' do
        expect do
          service.update_user(user_id: user_id, attributes: { email: 'taken@example.com' })
        end.to raise_error(Idp::ConflictError, /Failed to update user: User exists with same email/)
      end

      it 'does not send a verification email for a write that never landed' do
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
      before do
        stub_read_modify_write(representation: current_representation)
        stub_request(:put, actions_url).
          to_return(status: 500, body: { errorMessage: 'Failed to send email' }.to_json)
        allow(Sentry).to receive(:capture_exception_with_info)
      end

      it 'still reports the update as successful' do
        expect(service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })).to be true
      end

      # The profile write itself landing is asserted by the successful-update example above; the mail
      # leg failing doesn't unwind it, which is what 'still reports the update as successful' shows.

      # Swallowed, not dropped: nobody sees the failure unless it is reported.
      it 'reports the swallowed delivery failure' do
        service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })

        expect(Sentry).to have_received(:capture_exception_with_info).
          with(instance_of(Idp::ServiceError), /couldn't send the address verification email/)
      end

      # Only the mail leg is forgiven. A failed write still has to reach the caller.
      it 'does not swallow a failure from the profile write itself' do
        stub_request(:put, user_url).
          to_return(status: 400, body: { errorMessage: 'Invalid attribute' }.to_json)

        expect do
          service.update_user(user_id: user_id, attributes: { email: 'new@example.com' })
        end.to raise_error(Idp::ServiceError, /Failed to update user/)
      end
    end

    context 'when the user cannot be fetched first' do
      before { stub_request(:get, user_url).to_return(status: 404) }

      it 'raises ServiceError from the GET instead of PUTting a partial body' do
        expect do
          service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })
        end.to raise_error(Idp::ServiceError, /User not found/)
        expect(WebMock).not_to have_requested(:put, any_api_request)
      end
    end
  end

  describe '#get_user' do
    it 'returns the parsed representation' do
      stub_request(:get, user_url).
        to_return(status: 200, body: { id: user_id, username: 'test@example.com' }.to_json)

      expect(service.get_user(user_id: user_id)).to eq('id' => user_id, 'username' => 'test@example.com')
    end

    it 'raises a non-transient ServiceError when the user is not found' do
      stub_request(:get, user_url).to_return(status: 404)

      expect { service.get_user(user_id: user_id) }.
        to raise_error(Idp::ServiceError, /User not found: #{user_id}/) { |error|
          # The account is gone over there, so Idp::SyncUserFromIdpJob has to stop rather than retry
          # this user to its cooldown on a 404 that will never change.
          expect(error).not_to be_transient
        }
    end
  end

  # Keycloak parks the unconfirmed address in an internal user attribute
  describe '#pending_email' do
    # `extra` merges at the top level of the representation, so callers pass `attributes: {...}` to
    # nest one — the empty case means "a representation with no attributes key at all".
    def stub_representation(extra)
      stub_request(:get, user_url).
        to_return(status: 200, body: { id: user_id, email: 'before@example.com' }.merge(extra).to_json)
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
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    before { stub_read_modify_write(representation: current_representation) }

    it 'returns true and enables the user without clearing other fields' do
      result = service.reactivate_user(user_id: user_id)

      expect(result).to be true
      expect(
        a_request(:put, user_url).with(body: current_representation.merge(enabled: true)),
      ).to have_been_made
    end
  end

  describe '#deactivate_user' do
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    before { stub_read_modify_write(representation: current_representation) }

    it 'returns true and disables the user without clearing other fields' do
      result = service.deactivate_user(user_id: user_id)

      expect(result).to be true
      expect(
        a_request(:put, user_url).with(body: current_representation.merge(enabled: false)),
      ).to have_been_made
    end
  end

  describe '#set_required_action' do
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    before { stub_read_modify_write(representation: current_representation) }

    it 'returns true and sets the required actions without clearing other fields' do
      result = service.set_required_action(user_id: user_id, actions: ['UPDATE_PASSWORD'])

      expect(result).to be true
      expect(
        a_request(:put, user_url).with(body: current_representation.merge(requiredActions: ['UPDATE_PASSWORD'])),
      ).to have_been_made
    end
  end

  # Every one of these reads the representation back, merges its change in and PUTs the whole thing,
  # so a refused PUT is one code path. What each has to get right on its own is the failure message —
  # a caller looking at Sentry needs to know which call it was — and the merged body, which the
  # per-method success examples above assert.
  describe 'a refused write' do
    before do
      stub_read_modify_write(
        representation: { id: user_id, username: 'test@example.com' },
        put_status: 404,
        put_body: { error: 'User not found' }.to_json,
      )
    end

    {
      'reactivate_user' => [->(s, id) { s.reactivate_user(user_id: id) }, /Failed to reactivate user: User not found/],
      'deactivate_user' => [->(s, id) { s.deactivate_user(user_id: id) }, /Failed to deactivate user: User not found/],
      'set_required_action' => [
        ->(s, id) { s.set_required_action(user_id: id, actions: ['UPDATE_PASSWORD']) },
        /Failed to set required actions: User not found/,
      ],
      'update_user' => [
        ->(s, id) { s.update_user(user_id: id, attributes: { first_name: 'Jane' }) },
        /Failed to update user: User not found/,
      ],
    }.each do |name, (call, message)|
      it "raises a non-transient ServiceError naming #{name}" do
        expect { call.call(service, user_id) }.to raise_error(Idp::ServiceError, message) { |error|
          # 4xx: Keycloak answered, and it keeps giving the same answer until somebody changes
          # something there or in our config. Retrying it just burns the job's attempts.
          expect(error).not_to be_transient
        }
      end
    end
  end

  # What a struggling Keycloak actually returns, and it takes handle_response's fall-through branch
  # rather than either 4xx arm. Two things that branch owes the caller, asserted together: the failure
  # verb (Sentry groups on the operation, but a human reads the message) and the classification, which
  # points the other way from 4xx because a server having a bad minute is worth coming back to.
  describe 'a 5xx from the Admin API' do
    before do
      stub_read_modify_write(
        representation: { id: user_id, username: 'test@example.com' },
        put_status: 502,
        # Not JSON, because a gateway in front of Keycloak answers with its own page and this branch
        # reports the status rather than trying to read a message out of the body.
        put_body: '<html>502 Bad Gateway</html>',
      )
    end

    it 'raises a transient ServiceError naming both the call and the status' do
      expect { service.deactivate_user(user_id: user_id) }.
        to raise_error(Idp::ServiceError, /Failed to deactivate user: unexpected response from Keycloak \(502\)/) { |error|
          expect(error).to be_transient
        }
    end
  end

  # A diagnostic an operator reads on the connector config screen, so every failure has to name
  # something they can act on rather than a status code. It never raises — the return value is the
  # whole contract.
  describe '#test_connection' do
    let(:probe_url) { admin_url('/users?max=1') }

    it 'reports success when the Admin API answers' do
      stub_request(:get, probe_url).to_return(status: 200, body: { realm: realm }.to_json)

      result = service.test_connection

      expect(result[:success]).to be true
      expect(result[:message]).to include('Connection successful')
    end

    {
      'the credentials are refused' => [{ status: 401 }, 'Authentication failed'],
      'the endpoint is not there' => [{ status: 404 }, 'API endpoint not found'],
      'Keycloak itself errors' => [{ status: 500 }, 'Keycloak server error: 500'],
      'the connection is refused' => [Errno::ECONNREFUSED, 'Connection refused'],
      'the host is unreachable' => [Errno::EHOSTUNREACH, 'Host unreachable'],
      'the connection times out' => [:timeout, 'timeout'],
    }.each do |scenario, (outcome, message)|
      it "reports failure naming the cause when #{scenario}" do
        stub = stub_request(:get, probe_url)
        case outcome
        when :timeout then stub.to_timeout
        when Hash then stub.to_return(**outcome)
        else stub.to_raise(outcome)
        end

        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include(message)
      end
    end
  end

  describe 'token retry on 401' do
    # Two distinct tokens, so "fresh" is read off the wire rather than inferred from the number of
    # token round trips: a retry that refetched and then sent the stale bearer again looks identical
    # from the count alone, and would 401 forever.
    def stub_token_sequence
      issued = ['token-1', 'token-2'].map do |token|
        { status: 200, body: { access_token: token, expires_in: 300 }.to_json, headers: { 'Content-Type' => 'application/json' } }
      end
      stub_request(:post, token_url).to_return(*issued)
    end

    it 'retries once, carrying the newly issued token' do
      stub_token_sequence
      stub_request(:get, user_url).
        to_return(
          { status: 401, body: { error: 'invalid_token' }.to_json },
          { status: 200, body: { id: user_id, username: 'test@example.com' }.to_json },
        )

      result = service.get_user(user_id: user_id)

      expect(result).to include('id' => user_id)
      expect(a_request(:get, user_url).with(headers: { 'Authorization' => 'Bearer token-1' })).to have_been_made.once
      expect(a_request(:get, user_url).with(headers: { 'Authorization' => 'Bearer token-2' })).to have_been_made.once
    end

    it 'gives up after the one retry rather than looping on a token the realm keeps refusing' do
      stub_token_sequence
      stub_request(:get, user_url).to_return(status: 401, body: { error: 'invalid_token' }.to_json)

      expect { service.get_user(user_id: user_id) }.to raise_error(Idp::ServiceError, /Failed to get user/)
      expect(a_request(:get, user_url)).to have_been_made.times(2)
      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end
  end

  # Every call goes out behind this exchange, and the token stub these examples inherit matches
  # any body, so nothing else here would notice the credentials going out wrong.
  describe 'the client-credentials token exchange' do
    it 'posts the service account credentials to the realm token endpoint' do
      stub_request(:get, user_url).to_return(status: 200, body: { id: user_id }.to_json)

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
      stub_request(:get, user_url).to_return(status: 200, body: { id: user_id }.to_json)

      service.get_user(user_id: user_id)

      expect(
        a_request(:get, user_url).with(headers: { 'Authorization' => 'Bearer issued-token' }),
      ).to have_been_made
    end

    context 'when the token endpoint rejects the credentials' do
      before do
        stub_request(:post, token_url).
          to_return(status: 401, body: { error: 'invalid_client' }.to_json)
      end

      it 'raises rather than calling the Admin API unauthenticated' do
        expect { service.get_user(user_id: user_id) }.
          to raise_error(Idp::ServiceError, /Failed to obtain access token: 401/)

        expect(WebMock).not_to have_requested(:get, /#{Regexp.escape(admin_url)}/)
      end

      it 'tags the failure with the operation that produced it, and rules out a retry' do
        error = begin
          service.get_user(user_id: user_id)
        rescue Idp::ServiceError => e
          e
        end

        expect(error.operation).to eq(:access_token)
        expect(error.idp_name).to eq('Keycloak')
        # Refused credentials are an ops fix; retrying them just multiplies the pages.
        expect(error).not_to be_transient
      end
    end
  end

  describe 'token caching' do
    before do
      stub_request(:get, user_url).
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

  # Asserted, not probed (see the comment on #supports_email_self_service?), so these are literals in
  # the source: one example covering all of them is as much as they can be worth, and what it catches
  # is an override going missing and the base class's false showing through. There is no companion
  # "without touching the realm" example because a method that returns a literal cannot make a
  # request — the source comment is where the probe decision lives. #supports_session_logout? is the
  # only one that reads config, and it sits with #logout_user_sessions. The false side of every
  # predicate belongs to Idp::NullService's spec.
  describe 'the capability surface' do
    it 'advertises everything the Admin API can do, and names itself for operators' do
      expect(service.idp_name).to eq('Keycloak')
      expect(service.supports_user_management?).to be true
      expect(service.supports_profile_updates?).to be true
      expect(service.supports_user_creation?).to be true
      expect(service.supports_account_backfill?).to be true
      expect(service.supports_email_self_service?).to be true
    end
  end

  # An authenticate-only realm (manage_users: false) — a customer-operated Keycloak, or a service
  # account without the manage-users role. Management capability tracks the config flag, not the
  # class, while login and the self-service account console keep working.
  describe 'capabilities on an authenticate-only realm (manage_users: false)' do
    let(:service) do
      described_class.new(
        config: {
          api_url: api_url,
          realm: realm,
          client_id: client_id,
          client_secret: client_secret,
          manage_users: false,
        },
      )
    end

    it 'reports every management capability as false' do
      expect(service.supports_user_management?).to be false
      expect(service.supports_profile_updates?).to be false
      expect(service.supports_user_creation?).to be false
      expect(service.supports_account_backfill?).to be false
    end

    it 'still offers self-service email' do
      expect(service.supports_email_self_service?).to be true
    end
  end

  # Also the only reachable "unconfigured connector": the blank-api_url guards in #browser_url and
  # #supports_session_logout? sit behind this raise, so no service can be constructed in the state
  # they cover and there are no examples driving them through a mutated config hash. What actually
  # happens to such a connector belongs to its callers and is covered there — rescued at render time
  # (spec/requests/idp/account_emails_controller_spec.rb) and turned into a refused sign-out rather
  # than a silent one (spec/requests/idp/warehouse_jwt_wiring_spec.rb).
  describe 'config validation' do
    let(:complete) { { api_url: 'http://kc:8080', realm: 'r', client_id: 'x', client_secret: 'y' } }

    # Dropped one at a time rather than checking only the empty config: realm in particular has no
    # default, and a guard that only fired on a wholly blank config would pass that check while
    # letting three-quarters-configured connectors through.
    [:api_url, :realm, :client_id, :client_secret].each do |key|
      it "raises naming #{key} when it is the only one missing" do
        expect { described_class.new(config: complete.except(key)) }.
          to raise_error(Idp::ServiceError, /#{key}/)
      end
    end

    it 'lists all missing keys' do
      expect { described_class.new(config: {}) }.
        to raise_error(Idp::ServiceError, /api_url, realm, client_id, client_secret/)
    end
  end

  # No .from_config examples here on purpose: spec/models/idp/service_config_spec.rb asserts the same
  # four column => config-key mappings against a real persisted Idp::ServiceConfig. Covering it here
  # would mean faking that reader surface, and a fake can't notice a renamed column — the one failure
  # this translation actually has.

  describe '#account_action_url' do
    let(:redirect_uri) { 'https://warehouse.test/account/edit' }

    subject(:url) { service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: redirect_uri) }

    def query_param(key)
      Rack::Utils.parse_query(URI(url).query)[key]
    end

    it 'targets the realm authorize endpoint' do
      expect(url).to start_with("#{api_url}/realms/#{realm}/protocol/openid-connect/auth?")
    end

    # client_id here is the unconfigured default: Keycloak's own account client returns the user to
    # the Keycloak account console rather than here, but it exists on every realm, and a wrong
    # destination beats a dead link.
    it 'carries the action, client, redirect, and OIDC params' do
      expect(Rack::Utils.parse_query(URI(url).query)).to include(
        'kc_action' => 'UPDATE_PASSWORD',
        'client_id' => 'account',
        'redirect_uri' => redirect_uri,
        'response_type' => 'code',
        'scope' => 'openid',
      )
    end

    # The client's Base URL is where Keycloak sends the user back from an out-of-band confirmation
    # link, so which client the action runs under decides where an email change lands. It comes off
    # the config row (a per-realm column seeded from KEYCLOAK_ACCOUNT_CLIENT_ID once), not a
    # request-time ENV read; the unconfigured fallback to 'account' is asserted by the params example
    # above.
    describe 'the client the action runs under' do
      it 'runs under the account client from the config row' do
        service.config[:account_client_id] = 'from-config'

        expect(query_param('client_id')).to eq('from-config')
      end

      it 'ignores KEYCLOAK_ACCOUNT_CLIENT_ID in the environment' do
        stub_const('ENV', ENV.to_h.merge('KEYCLOAK_ACCOUNT_CLIENT_ID' => 'warehouse-account'))

        expect(query_param('client_id')).to eq('account')
      end
    end
  end

  # Back channel rather than an RP-initiated logout redirect: the app is handed Dex's id_token, not
  # Keycloak's, so there's no id_token_hint to send. The Admin API doesn't need one.
  describe '#logout_user_sessions' do
    let(:logout_path) { admin_url('/users/abc/logout') }

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

    # Named rather than `StandardError`: the point is that the socket failure reaches the caller
    # unconverted (the controller has a rescue for exactly this), and StandardError would also be
    # satisfied by a NoMethodError from a typo in this spec.
    it 'raises rather than returning quietly when Keycloak is unreachable' do
      stub_request(:post, logout_path).to_timeout

      expect { service.logout_user_sessions(user_id: 'abc') }.to raise_error(Timeout::Error)
    end

    it 'is advertised by the capability predicate' do
      expect(service.supports_session_logout?).to eq(true)
    end
  end

  # Browser links come off the public URL; Admin API calls must not.
  describe 'the browser-facing URL override' do
    let(:public_url) { 'https://keycloak.public.test' }

    shared_examples 'honors the browser URL' do
      it 'builds account action deep-links from it' do
        url = service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: 'https://warehouse.test/account/edit')

        expect(url).to start_with("#{public_url}/realms/#{realm}/protocol/openid-connect/auth?")
      end

      it 'leaves Admin API calls on api_url' do
        stub_request(:get, user_url('abc')).
          to_return(status: 200, body: { id: 'abc' }.to_json, headers: { 'Content-Type' => 'application/json' })

        service.get_user(user_id: 'abc')

        expect(a_request(:get, user_url('abc'))).to have_been_made
        expect(a_request(:any, /#{Regexp.escape(public_url)}/)).not_to have_been_made
      end
    end

    # browser_url is a per-realm Idp::ServiceConfig column (seeded from ENV once); it is not read from
    # ENV at request time, so a stray KEYCLOAK_PUBLIC_URL must not leak into a DB-configured service.
    context 'supplied in the config hash' do
      before do
        stub_const('ENV', ENV.to_h.merge('KEYCLOAK_PUBLIC_URL' => 'https://ignored.test'))
        service.config[:browser_url] = public_url
      end

      include_examples 'honors the browser URL'
    end

    context 'not set in config' do
      before { stub_const('ENV', ENV.to_h.merge('KEYCLOAK_PUBLIC_URL' => 'https://ignored.test')) }

      it 'falls back to api_url, ignoring ENV' do
        url = service.account_action_url(action: 'UPDATE_PASSWORD', redirect_uri: 'https://warehouse.test/account/edit')

        expect(url).to start_with("#{api_url}/realms/#{realm}/protocol/openid-connect/auth?")
      end
    end
  end

  describe '#each_user' do
    def stub_page(first, max, users)
      stub_request(:get, admin_url('/users')).
        with(query: { first: first.to_s, max: max.to_s }).
        to_return(
          status: 200,
          body: users.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
    end

    it 'pages past the first full page and stops on the final short page' do
      stub_page(0, 2, Array.new(2) { |i| { 'id' => "id-#{i}", 'email' => "u#{i}@example.com" } })
      stub_page(2, 2, [{ 'id' => 'id-2', 'email' => 'u2@example.com' }])

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

    # Literals rather than the constants themselves: read from the source, these would only confirm
    # that whatever budget is configured reached the socket, and would say nothing about whether it
    # is short enough to keep a hung Keycloak off a request thread — the reason the budget exists.
    # Raising IO_TIMEOUT_SECONDS to 300, or dropping BULK_IO_TIMEOUT_SECONDS to the default, has to
    # turn something red. [open, read, write].
    let(:default_timeouts) { [2, 3, 3] }
    let(:bulk_timeouts) { [2, 30, 30] }

    it 'gives an ordinary call the short defaults' do
      stub_request(:post, admin_url('/users/user-1/logout')).to_return(status: 204)

      service.logout_user_sessions(user_id: 'user-1')

      expect(timeouts_of("/admin/realms/#{realm}/users/user-1/logout")).to eq([default_timeouts])
      # The token round trip a call makes on the way is on the default budget too.
      expect(timeouts_of("/realms/#{realm}/protocol/openid-connect/token")).to eq([default_timeouts])
    end

    it 'gives a bulk call a longer read and write budget' do
      stub_request(:post, admin_url('/partialImport')).to_return(status: 200, body: '{}')

      service.partial_import({ users: [] })

      expect(timeouts_of("/admin/realms/#{realm}/partialImport")).to eq([bulk_timeouts])
    end

    it 'keeps the longer budget on the 401 token retry' do
      stub_request(:post, admin_url('/partialImport')).
        to_return({ status: 401 }, { status: 200, body: '{}' })

      service.partial_import({ users: [] })

      expect(timeouts_of("/admin/realms/#{realm}/partialImport")).to eq([bulk_timeouts, bulk_timeouts])
    end

    it 'gives the paginated user listing the longer budget' do
      stub_request(:get, admin_url('/users')).
        with(query: { first: '0', max: '100' }).
        to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      service.each_user.to_a

      expect(timeouts_of("/admin/realms/#{realm}/users?first=0&max=100")).to eq([bulk_timeouts])
    end
  end

  describe 'the internal CA certificate' do
    let(:sent) { {} }

    before do
      recorded = sent
      allow_any_instance_of(Net::HTTP).to receive(:request).and_wrap_original do |original, *args|
        http = original.receiver
        recorded[args.first.path] = { use_ssl: http.use_ssl?, ca_file: http.ca_file }
        original.call(*args)
      end
    end

    # File.exist? is consulted for other paths too, so stub only the cert path and pass the rest through.
    def stub_cert_present(present)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(described_class::CA_CERT_FILE).and_return(present)
    end

    context 'over an https connection' do
      let(:api_url) { 'https://keycloak.test:8443' }

      it 'points Net::HTTP at the bundled cert when it exists' do
        stub_cert_present(true)
        stub_request(:get, user_url).to_return(status: 200, body: { id: user_id }.to_json)

        service.get_user(user_id: user_id)

        expect(sent.fetch("/admin/realms/#{realm}/users/#{user_id}")).to include(
          use_ssl: true,
          ca_file: described_class::CA_CERT_FILE.to_s,
        )
      end

      it 'leaves ca_file at the system default when the cert is absent' do
        stub_cert_present(false)
        stub_request(:get, user_url).to_return(status: 200, body: { id: user_id }.to_json)

        service.get_user(user_id: user_id)

        expect(sent.fetch("/admin/realms/#{realm}/users/#{user_id}")).to include(
          use_ssl: true,
          ca_file: nil,
        )
      end
    end
  end

  describe '#ensure_group' do
    let(:groups_url) { admin_url('/groups') }

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
