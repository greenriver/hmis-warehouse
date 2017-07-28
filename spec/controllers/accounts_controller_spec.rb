require 'rails_helper'

RSpec.describe AccountsController, type: :controller do

  # TODO - get auth working in tests
  let(:user) { create :user }

  before(:each) do
    authenticate(user)
  end

  describe "GET edit" do
    it 'renders edit' do
      get :edit
      expect( response ).to render_template :edit
    end
  end

end
