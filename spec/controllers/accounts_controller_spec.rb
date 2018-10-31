require 'rails_helper'

RSpec.describe AccountsController, type: :controller do

  # TODO - get auth working in tests
  let(:user) { create :user }
  let(:email)  { ActionMailer::Base.deliveries.last }

  before(:each) do
    authenticate(user)
  end

  describe "GET edit" do
    before(:each) do
      get :edit
    end

    it 'assigns user' do
      expect( assigns(:user) ).to eq user
    end

    it 'renders edit' do
      expect( response ).to render_template :edit
    end
  end

  describe "PUT update" do

    context 'with no current password' do
      before(:each) do
        patch :update, user: { first_name: 'Joe', email: 'info@greenriver.com' }
      end
      it 'does not update' do
        expect( User.not_system.first.first_name ).to_not eq 'Joe'
      end
      it 'has an error' do
        expect( assigns(:user).errors.count ).to eq 1
      end
      it 'renders edit' do
        expect( response ).to render_template :edit
      end
    end

    context 'with current password' do

      let(:changes) do
        {
          first_name: 'Fake',
          last_name: 'User',
          email: 'info@greenriver.com',
          current_password: Digest::SHA256.hexdigest('abcd1234abcd1234')
        }
      end

      before(:each) do
        patch :update, user: changes
      end
      it 'updates first_name' do
        expect( User.not_system.first.first_name ).to eq changes[:first_name]
      end
      it 'updates last_name' do
        expect( User.not_system.first.last_name ).to eq changes[:last_name]
      end
      it 'updates email' do
        assigns(:user).confirm
        expect( User.not_system.first.email ).to eq changes[:email]
      end
      it 'sends an email confirmation email' do
        expect( email.to ).to eq [changes[:email]]
      end
      it 'redirects to edit' do
        expect( response ).to redirect_to edit_account_path
      end

      context 'when changing password' do

        let(:changes) do
          {
            current_password: Digest::SHA256.hexdigest('abcd1234abcd1234'),
            password: Digest::SHA256.hexdigest('secret12'),
            password_confirmation: Digest::SHA256.hexdigest('secret12')
          }
        end

        it 'sends password confirmation email' do
          patch :update, user: changes
          expect( email.to ).to eq [user.email]
        end
        
      end
    end
  end

end
