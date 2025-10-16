# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsController, type: :request do
  # TODO: - get auth working in tests
  let(:user) { create :user }
  let(:email) { ActionMailer::Base.deliveries.last }

  before(:each) do
    sign_in(user)
  end

  describe 'GET edit' do
    before(:each) do
      get edit_account_path
    end

    it 'assigns user' do
      expect(assigns(:user)).to eq user
    end

    it 'renders edit' do
      expect(response).to render_template :edit
    end
  end

  describe 'PUT update' do
    let(:changes) do
      {
        first_name: 'Fake',
        last_name: 'User',
      }
    end

    it 'updates first_name and last_name and redirects to edit' do
      patch account_path, params: { user: changes }
      expect(User.not_system.first.first_name).to eq changes[:first_name]
      expect(User.not_system.first.last_name).to eq changes[:last_name]
      expect(response).to redirect_to edit_account_path
    end

    context 'with specific changes' do
      it 'sets the flash notice for name changes' do
        user = create(:user, first_name: 'Original', last_name: 'Name', email_schedule: 'daily', phone: '1112223333', credentials: 'old')
        sign_in(user)
        changes = {
          first_name: 'Updated',
          last_name: 'Name',
          email_schedule: user.email_schedule,
          phone: user.phone,
          credentials: user.credentials,
        }
        patch account_path, params: { user: changes }
        expect(flash[:notice]).to eq('Account name was updated.')
      end

      it 'sets the flash notice for credentials changes' do
        user = create(:user, first_name: 'Original', last_name: 'Name', email_schedule: 'daily', phone: '1112223333', credentials: 'old')
        sign_in(user)
        changes = {
          first_name: user.first_name,
          last_name: user.last_name,
          email_schedule: user.email_schedule,
          phone: user.phone,
          credentials: 'new',
        }
        patch account_path, params: { user: changes }
        expect(flash[:notice]).to eq('User credentials were changed.')
      end

      it 'sets the flash notice for email schedule changes' do
        user = create(:user, first_name: 'Original', last_name: 'Name', email_schedule: 'immediate', phone: '1112223333', credentials: 'old')
        sign_in(user)
        changes = {
          first_name: user.first_name,
          last_name: user.last_name,
          email_schedule: 'daily',
          phone: user.phone,
          credentials: user.credentials,
        }
        patch account_path, params: { user: changes }
        expect(flash[:notice]).to eq('Email schedule was updated.')
      end

      it 'sets the flash notice for phone changes' do
        user = create(:user, first_name: 'Original', last_name: 'Name', email_schedule: 'daily', phone: '1112223333', credentials: 'old')
        sign_in(user)
        changes = {
          first_name: user.first_name,
          last_name: user.last_name,
          email_schedule: user.email_schedule,
          phone: '1234567890',
          credentials: user.credentials,
        }
        patch account_path, params: { user: changes }
        expect(flash[:notice]).to eq('Phone number was updated.')
      end

      it 'joins the flash notices for multiple changes' do
        agency = create(:agency)
        user = create(:user, first_name: 'Original', last_name: 'Name', email_schedule: 'immediate', phone: '1112223333', credentials: 'old', agency: agency)
        sign_in(user)
        changes = {
          first_name: 'Updated',
          last_name: 'User',
          credentials: 'new_credentials',
          email_schedule: 'daily',
          phone: '1234567890',
        }
        patch account_path, params: { user: changes }
        expect(flash[:notice]).to eq('Account name was updated. User credentials were changed. Email schedule was updated. Phone number was updated.')
      end
    end
  end
end
