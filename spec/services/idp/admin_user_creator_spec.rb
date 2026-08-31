###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# AdminUserCreator builds a local User without a password, which only validates under the JWT
# boot (AUTH_METHOD=jwt); under Devise, User is :secure_validatable and requires one.
RSpec.describe Idp::AdminUserCreator, :jwt_only do
  let(:connector_id) { 'kc' }
  let(:agency) { create(:agency) }
  let(:service) { instance_double(Idp::KeycloakService, supports_user_creation?: true, idp_name: 'Keycloak') }

  before do
    allow(Idp::ServiceFactory).to receive(:for_connector).with(connector_id).and_return(service)
  end

  def call(email: 'newbie@example.com', **overrides)
    described_class.call(
      **{ connector_id: connector_id, email: email, first_name: 'New', last_name: 'User', agency_id: agency.id }.merge(overrides),
    )
  end

  context 'when the email is new to the IdP' do
    before do
      allow(service).to receive(:find_user_by_email).and_return(nil)
      allow(service).to receive(:create_user).and_return(success: true, connector_user_id: 'kc-new')
    end

    it 'provisions a new remote account and links the returned connector id' do
      user = call

      expect(user).to be_persisted
      expect(user.agency_id).to eq(agency.id)
      expect(user.last_connector_id).to eq(connector_id)
      expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to eq([[connector_id, 'kc-new']])
      expect(service).to have_received(:create_user).with(email: 'newbie@example.com', first_name: 'New', last_name: 'User')
    end

    it 'rejects a blank agency before provisioning anything remotely' do
      expect { call(agency_id: nil) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(service).not_to have_received(:create_user)
    end
  end

  # 'None' in the admin form: a realm we can't provision into (Okta, say). The account is matched
  # by email on first sign-in, so no service is built and no connector link is written.
  context 'when no connector is chosen' do
    before { allow(Idp::ServiceFactory).to receive(:for_connector).with(nil).and_call_original }

    it 'resolves a NullService and creates a local-only user with no remote call' do
      user = call(connector_id: nil)

      expect(user).to be_persisted
      expect(user.last_connector_id).to be_nil
      expect(user.user_authentication_sources).to be_empty
    end

    # The link happens by email on first sign-in, and payload_email is downcased and stripped. A
    # mixed-case, space-padded entry here must be stored normalized so it resolves the same account
    # rather than provisioning a duplicate.
    it 'normalizes the email so first sign-in links the same account instead of duplicating it' do
      user = call(connector_id: nil, email: '  Mixed.Case@Example.com  ')
      expect(user.email).to eq('mixed.case@example.com')

      jwt_helper = instance_double(
        Idp::JwtHelper,
        token?: true,
        valid?: true,
        connector_id: nil,
        connector_user_id: nil,
        payload_email: 'mixed.case@example.com',
        first_name: 'Mixed',
        last_name: 'Case',
      )

      expect { User.find_or_create_from_jwt(jwt_helper) }.not_to change(User, :count)
      expect(User.find_or_create_from_jwt(jwt_helper)).to eq(user)
    end
  end

  context 'when the email already exists in the IdP' do
    before do
      allow(service).to receive(:find_user_by_email).and_return('id' => 'kc-existing')
      allow(service).to receive(:create_user)
    end

    it 'links the existing remote account instead of creating a duplicate' do
      user = call

      expect(user.user_authentication_sources.pluck(:connector_user_id)).to eq(['kc-existing'])
      expect(service).not_to have_received(:create_user)
    end
  end

  # A lookup hit that carries no usable id is not a match: Keycloak can return a representation
  # whose id we can't link on, so fall through to creating the account rather than writing a blank
  # connector_user_id.
  context 'when the IdP lookup returns a hash with no usable id' do
    before do
      allow(service).to receive(:find_user_by_email).and_return('id' => '')
      allow(service).to receive(:create_user).and_return(success: true, connector_user_id: 'kc-new')
    end

    it 'provisions a new remote account and links the created id' do
      user = call

      expect(user.user_authentication_sources.pluck(:connector_user_id)).to eq(['kc-new'])
      expect(service).to have_received(:create_user).with(email: 'newbie@example.com', first_name: 'New', last_name: 'User')
    end
  end

  # Provisioning claims the email locally first, then calls the remote IdP. A failure after that
  # local save must roll the local user back, or a failed attempt permanently owns the unique email
  # and no retry for that address can ever succeed.
  context 'when the remote provisioning call fails' do
    before do
      allow(service).to receive(:find_user_by_email).and_return(nil)
      allow(service).to receive(:create_user).
        and_raise(Idp::ServiceError.new('boom', idp_name: 'Keycloak', operation: :create_user, transient: true))
    end

    it 'rolls the local user back and re-raises, leaving the email free to retry' do
      expect { call }.to raise_error(Idp::ServiceError)

      expect(User.find_by(email: 'newbie@example.com')).to be_nil
      expect(Idp::UserAuthenticationSource.where(connector_id: connector_id)).to be_empty
    end
  end

  context 'when the email is already taken locally' do
    let!(:existing) { create(:user, email: 'dup@example.com') }

    before { allow(service).to receive(:find_user_by_email) }

    it 'raises RecordInvalid before provisioning anything remotely' do
      expect { call(email: 'dup@example.com') }.to raise_error(ActiveRecord::RecordInvalid)
      expect(service).not_to have_received(:find_user_by_email)
    end
  end

  context 'when the connector cannot create users' do
    let(:service) { instance_double(Idp::NullService, supports_user_creation?: false, idp_name: 'Unknown IDP') }

    before { allow(service).to receive(:find_user_by_email) }

    it 'creates a local-only, email-keyed user with no remote call and no connector link' do
      user = call

      expect(user).to be_persisted
      expect(user.email).to eq('newbie@example.com')
      expect(user.last_connector_id).to be_nil
      expect(user.user_authentication_sources).to be_empty
      expect(service).not_to have_received(:find_user_by_email)
    end
  end

  # The HMIS admin arm provisions Hmis::User (same table, different mapping) through the same
  # service by passing user_class:. Lock in that cross-model contract.
  context 'with a custom user_class' do
    before do
      allow(service).to receive(:find_user_by_email).and_return(nil)
      allow(service).to receive(:create_user).and_return(success: true, connector_user_id: 'kc-new')
    end

    it 'persists and links an instance of the given class' do
      user = call(email: 'hmis@example.com', first_name: 'H', last_name: 'M', user_class: Hmis::User)

      expect(user).to be_a(Hmis::User)
      expect(user).to be_persisted
      expect(user.last_connector_id).to eq(connector_id)
      expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to eq([[connector_id, 'kc-new']])
    end
  end
end
