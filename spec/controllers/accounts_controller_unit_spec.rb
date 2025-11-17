# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsController, type: :controller do
  let(:user) { create(:user, first_name: 'Original', last_name: 'User', credentials: 'old_creds', email_schedule: 'daily', phone: '1234567890') }
  let(:controller_instance) { described_class.new }
  let(:flash_hash) { {} }

  before do
    allow(controller_instance).to receive(:current_user).and_return(user)
    allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new(user: account_params))
    allow(controller_instance).to receive(:redirect_to)
    allow(controller_instance).to receive(:bypass_sign_in)
    allow(controller_instance).to receive(:flash).and_return(flash_hash)
    allow(controller_instance).to receive(:edit_account_path).and_return('/account/edit')
    controller_instance.instance_variable_set(:@user, user)
  end

  describe '#update method string manipulation' do
    context 'when no changes are made' do
      let(:account_params) do
        {
          first_name: user.first_name,
          last_name: user.last_name,
          credentials: user.credentials,
          email_schedule: user.email_schedule,
          phone: user.phone,
          agency_id: user.agency_id&.to_s,
        }
      end

      it 'does not set flash notice when no changes detected' do
        controller_instance.update
        expect(flash_hash[:notice]).to be_nil
      end
    end

    context 'when single field is changed' do
      let(:account_params) do
        {
          first_name: 'Updated',
          last_name: user.last_name,
          credentials: user.credentials,
          email_schedule: user.email_schedule,
          phone: user.phone,
          agency_id: user.agency_id&.to_s,
        }
      end

      it 'sets flash notice with single change message' do
        controller_instance.update
        expect(flash_hash[:notice]).to eq('Account name was updated.')
      end
    end

    context 'when multiple fields are changed' do
      let(:account_params) do
        {
          first_name: 'Updated',
          last_name: 'Name',
          credentials: 'new_creds',
          email_schedule: 'immediate',
          phone: '9876543210',
          agency_id: user.agency_id&.to_s,
        }
      end

      it 'sets flash notice with multiple change messages joined by spaces' do
        controller_instance.update
        expected_message = 'Account name was updated. User credentials were changed. Email schedule was updated. Phone number was updated.'
        expect(flash_hash[:notice]).to eq(expected_message)
      end
    end
  end
end
