require 'rails_helper'

RSpec.describe AccountPasswordsController, type: :controller do

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

      let(:changes) do
        {
            password: Digest::SHA256.hexdigest('secret12'),
            password_confirmation: Digest::SHA256.hexdigest('secret12')
        }
      end

      it 'has an error' do
        patch :update, user: changes
        expect( assigns(:user).errors.count ).to eq 1
      end
    end

    context 'with current password' do

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
