require 'rails_helper'

RSpec.describe WarehouseReports::TouchPointExportsController, type: :controller do

  let(:user) { create :user }
  let(:admin_role) { create :admin_role }
  
  before(:each) do
    user.roles << admin_role
    authenticate(user)
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
