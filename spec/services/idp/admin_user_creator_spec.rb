###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# AdminUserCreator builds a local User without a password, which only validates under the JWT
# boot (AUTH_METHOD=jwt); under Devise, User is :secure_validatable and requires one.
RSpec.describe Idp::AdminUserCreator, if: AuthMethod.jwt? do
  let(:connector_id) { 'kc' }
  let(:service) { instance_double(Idp::KeycloakService, supports_user_creation?: true, idp_name: 'Keycloak') }

  before do
    allow(Idp::ServiceFactory).to receive(:for_connector).with(connector_id).and_return(service)
  end

  def call(email: 'newbie@example.com')
    described_class.call(connector_id: connector_id, email: email, first_name: 'New', last_name: 'User')
  end

  context 'when the email is new to the IdP' do
    before do
      allow(service).to receive(:find_user_by_email).and_return(nil)
      allow(service).to receive(:create_user).and_return(success: true, connector_user_id: 'kc-new')
    end

    it 'provisions a new remote account and links the returned connector id' do
      user = call

      expect(user).to be_persisted
      expect(user.last_connector_id).to eq(connector_id)
      expect(user.user_authentication_sources.pluck(:connector_id, :connector_user_id)).to eq([[connector_id, 'kc-new']])
      expect(service).to have_received(:create_user).with(email: 'newbie@example.com', first_name: 'New', last_name: 'User')
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

    it 'raises a ServiceError and creates nothing' do
      expect { call }.to raise_error(Idp::ServiceError)
      expect(User.find_by(email: 'newbie@example.com')).to be_nil
    end
  end
end
