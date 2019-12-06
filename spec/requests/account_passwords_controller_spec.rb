require 'rails_helper'

RSpec.describe AccountPasswordsController, type: :request do
  # TODO: - get auth working in tests
  let(:user) { create :user }
  let(:email)  { ActionMailer::Base.deliveries.last }

  before(:each) do
    sign_in(user)
  end

  describe 'GET edit' do
    before(:each) do
      get edit_account_password_path
    end

    it 'assigns user' do
      expect(assigns(:user)).to eq user
    end

    it 'renders edit' do
      expect(response).to render_template :edit
    end
  end

  describe 'PUT update' do
    context 'with no current password' do
      let(:changes) do
        {
          password: Digest::SHA256.hexdigest('secret12'),
          password_confirmation: Digest::SHA256.hexdigest('secret12'),
        }
      end

      before(:each) do
        patch account_password_path, user: changes
      end

      it 'has an error' do
        expect(assigns(:user).errors.count).to eq 1
      end
      it 'redirects to edit' do
        expect(response).to redirect_to edit_account_password_path
      end
    end

    context 'with current password' do
      let(:changes) do
        {
          current_password: Digest::SHA256.hexdigest('abcd1234abcd1234'),
          password: Digest::SHA256.hexdigest('secret12'),
          password_confirmation: Digest::SHA256.hexdigest('secret12'),
        }
      end

      before(:each) do
        patch account_password_path, user: changes
      end

      it 'sends password confirmation email' do
        expect(email.to).to eq [user.email]
      end
      it 'redirects to edit' do
        expect(response).to redirect_to edit_account_password_path
      end
    end
  end
end
